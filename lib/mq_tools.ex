defmodule MQTools do
  import Supervisor.Spec, only: [
    worker: 2,
    supervisor: 2
  ]

  def start(_, _) do

    conn_opts = case Application.fetch_env(:mq_tools, :connection) do
      {:ok, opts} -> opts
      :error -> raise "Missing config option: mq_tools.connection"
    end

    # this needs to be revised, as we probably don't wanna restart requests on client failure etc.
    # Might break concurent requests when one of them fail.

    Supervisor.start_link([
      worker(MQTools.AMQPConnection, [conn_opts]),
      worker(MQTools.Client.Requests, []),
      worker(MQTools.Client, []),
      worker(MQTools.Provider.Dispatcher, []),
      supervisor(MQTools.Provider.HandlerSupervisor, [])
    ], strategy: :one_for_all, name: __MODULE__)

  end

  def amqp_connection do
    GenServer.call(MQTools.AMQPConnection, :conn)
  end

end
