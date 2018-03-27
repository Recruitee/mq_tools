require Logger

defmodule MQTools.ProviderError, do: defexception [:message]

defmodule MQTools.Client do

  use GenServer
  import MQTools.Packer, only: [pack: 1, unpack: 1]

  alias MQTools.Client.Requests

  def call(name, params, timeout \\ 10000) do
    GenServer.call(__MODULE__, {:call, name, params}, timeout)
  end

  def call!(name, params) do
    {:ok, value} = call(name, params)

    case value do
      %{"provider_error" => error} ->
        raise MQTools.ProviderError, message: error
      _ ->
        value
    end
  end

  def publish(name, params) do
    GenServer.cast(__MODULE__, {:publish, name, params})
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # CALLBACKS

  def init(_) do
    conn = MQTools.amqp_connection
    {:ok, chan} = AMQP.Channel.open(conn)
    {:ok, %{queue: queue}} = AMQP.Queue.declare(chan)
    {:ok, _} = AMQP.Basic.consume(chan, queue)
    {:ok, %{
        reply_queue: queue,
        chan: chan}}
  end

  def handle_call({:call, name, params}, from, state) do
    correlation_id = UUID.uuid1()
    AMQP.Basic.publish(state.chan, "", name, pack(params),
      reply_to: state.reply_queue, correlation_id: correlation_id)
    :ok = Requests.put(correlation_id, from)
    {:noreply, state}
  end

  def handle_cast({:publish, name, params}, _from, state) do
    AMQP.Basic.publish(state.chan, "", name, pack(params))
    {:noreply, state}
  end

  def handle_info({:basic_consume_ok, info}, state) do
    Logger.debug "Client consumer set: #{inspect info}"
    {:noreply, state}
  end

  def handle_info({:basic_cancel, info}, state) do
    Logger.error "Client consumer canceled: #{inspect info}"
    {:noreply, state}
  end

  def handle_info({:basic_deliver, payload, meta}, state) do
    decoded = unpack(payload)
    cond do
      meta.routing_key == state.reply_queue ->
        AMQP.Basic.ack(state.chan, meta.delivery_tag)
        unpack(payload) |> handle_reply(meta, state)
      true ->
        Logger.warn "Unroutable message: #{inspect decoded} -- #{inspect meta}"
    end
    {:noreply, state}
  end

  defp handle_reply(decoded, meta, state) do
    cid = meta.correlation_id
    receiver = Requests.get(cid)
    if receiver do
      GenServer.reply(receiver, {:ok, decoded})
      Requests.delete(cid)
      {:noreply, state}
    else
      Logger.warn "Uncorrelated reply: #{inspect decoded}"
      {:noreply, state}
    end
  end

end
