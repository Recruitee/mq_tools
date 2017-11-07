defmodule MQTools do
  import Supervisor.Spec, only: [
    worker: 2,
    supervisor: 2
  ]

  def start(_, _) do
    children = if Application.get_env(:mq_tools, :mq_provider), do:
      [worker(MQTools.Provider.Dispatcher, []),
      supervisor(MQTools.Provider.HandlerSupervisor, [])],
    else: []

    Supervisor.start_link(children ++ [
      worker(MQTools.Client.Requests, []),
      worker(MQTools.AMQPConnection, []),
    ], strategy: :one_for_one, name: __MODULE__)
  end

  def amqp_connection do
    GenServer.call(MQTools.AMQPConnection, :conn)
  end

end
