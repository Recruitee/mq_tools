require Logger

defmodule MQTools.AMQPConnection do
  @moduledoc """
  Wrapper around AMQP connection. Attempts to connect forever until
  it succeeds, then monitors the connection and dies with it.

  The underlying `AMQP.Connection` can be retrieved by calling:
    `GenServer.call(MQTools.AMQPConnection, :conn)`

  The result of this will be valid only until it dies, so the caller
  should be restarted by the same supervisor which sets up a new
  connections.
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts), do: rabbitmq_connect(opts)

  def terminate(_, _), do: :ok

  def handle_call(:conn, _from, conn), do: {:reply, conn, conn}

  def handle_info({:DOWN, _, _, _, _}, conn), do: {:stop, :kill, conn}

  defp rabbitmq_connect(opts) do
    retry_interval = opts[:retry_interval]
    connection_opts = opts |> Keyword.delete(:retry_interval)

    Logger.info("Trying to connect to broker")

    case AMQP.Connection.open(connection_opts) do
      {:ok, conn} ->
        Process.monitor(conn.pid)
        {:ok, conn}

      {:error, err} ->
        Logger.error("Connecting to broker failed: #{inspect(err)}")
        :timer.sleep(retry_interval)
        rabbitmq_connect(retry_interval)
    end
  end
end
