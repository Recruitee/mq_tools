defmodule MQTools.Provider.Dispatcher do
  @moduledoc ~S"""
  Handles incoming and outgoing AMQP messages

  On startup, each queue for the RPC handlers
  is subscribed to.
  """

  require Logger

  def start_link do
    pid = spawn_link(&run/0)
    Logger.info("Started dispatcher #{inspect(pid)}")
    Process.register(pid, __MODULE__)
    {:ok, pid}
  end

  def run do
    conn = MQTools.amqp_connection()
    {:ok, chan} = AMQP.Channel.open(conn)

    for {queue, module} <- rpc_handler_queues() do
      AMQP.Queue.declare(chan, queue)
      AMQP.Queue.bind(chan, queue, "amq.direct")
      {:ok, _} = AMQP.Basic.consume(chan, queue)
      Logger.info("RPC handler module #{module} is consuming #{queue}")
    end

    loop(chan)
  rescue
    e ->
      Logger.error("Failed to start #{__MODULE__}:\n#{Exception.format(:error, e)}")
  end

  defp loop(chan) do
    receive do
      {:basic_consume_ok, _} ->
        nil

      {:basic_deliver, payload, meta} ->
        if dispatch(payload, meta) do
          AMQP.Basic.ack(chan, meta.delivery_tag)
        else
          AMQP.Basic.nack(chan, meta.delivery_tag)
        end

      {:reply, payload, %{reply_to: reply_to} = meta} when is_binary(reply_to) ->
        Logger.debug(
          "Replying to RPC #{meta.routing_key} (#{meta.correlation_id})" <> " | " <> payload
        )

        AMQP.Basic.publish(chan, "", reply_to, payload, correlation_id: meta.correlation_id)

      other ->
        Logger.debug("#{__MODULE__} ignoring #{inspect(other)}")
    end

    loop(chan)
  end

  defp dispatch(data, meta) do
    handler =
      Enum.find(
        rpc_handler_queues(),
        fn {q, _} -> q == meta.routing_key end
      )

    case handler do
      {queue, module} ->
        Logger.debug("Handling RPC #{meta.routing_key} (#{meta.correlation_id})" <> " | " <> data)
        MQTools.Provider.HandlerSupervisor.spawn_handler([module, queue, data, meta])

      _ ->
        Logger.debug("Not handling unknown RPC #{meta.routing_key}")
        false
    end
  end

  defp rpc_handler_queues do
    provider_modules = Application.get_env(:mq_tools, :rpc_providers, [])

    Enum.flat_map(provider_modules, fn provider_module ->
      Enum.map(provider_module.rpc_names, fn name ->
        {name, provider_module}
      end)
    end)
  end
end
