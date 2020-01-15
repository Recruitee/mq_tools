require Logger
defmodule MQTools do
  import Supervisor.Spec, only: [
    worker: 2,
    supervisor: 2
  ]

  def start(_, _) do
    conn_opts = Application.get_env(:mq_tools, :connection)
    queue_opts = Application.get_env(:mq_tools, :queue_opts, [])

    children = if conn_opts do
      [
        worker(MQTools.AMQPConnection, [conn_opts]),
        worker(MQTools.Client.Requests, []),
        worker(MQTools.Client, [queue_opts]),
        worker(MQTools.Provider.Dispatcher, []),
        supervisor(MQTools.Provider.HandlerSupervisor, [])
      ]
    else
      Logger.info "MQTools did not start providers and client, missing config option: mq_tools.connection"
      []
    end

    # this needs to be revised, as we probably don't wanna restart requests on client failure etc.
    # Might break concurent requests when one of them fail.
    Supervisor.start_link(children, strategy: :one_for_all, name: __MODULE__)
  end

  def amqp_connection do
    GenServer.call(MQTools.AMQPConnection, :conn)
  end

end
