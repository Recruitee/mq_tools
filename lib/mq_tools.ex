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

    children = if Application.get_env(:mq_tools, :rpc_providers), do:
      [worker(MQTools.Provider.Dispatcher, []),
      supervisor(MQTools.Provider.HandlerSupervisor, [])],
    else: []

    # this needs to be revised, as we probably don't wanna restart requests on client failure etc.
    # Might break concurent requests when one of them fail.

    Supervisor.start_link([
      worker(MQTools.AMQPConnection, [conn_opts]),
      worker(MQTools.Client.Requests, []),
      worker(MQTools.Client, []),
    ] ++ children, strategy: :one_for_all, name: __MODULE__)

  end

  def amqp_connection do
    GenServer.call(MQTools.AMQPConnection, :conn)
  end

end
