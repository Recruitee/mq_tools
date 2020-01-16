defmodule MQTools.Provider.Handler do
  import MQTools.Packer, only: [pack: 1, unpack: 1]

  def start_link(module, queue, data, meta) do
    pid = spawn_link(__MODULE__, :run, [module, queue, data, meta])
    {:ok, pid}
  end

  def run(module, queue, data, meta) do
    reply = module.handle_rpc(queue, unpack(data))
    send(MQTools.Provider.Dispatcher, {:reply, pack(reply), meta})
  rescue
    e ->
      stacktrace = System.stacktrace()
      reply = %{"provider_error" => Exception.format(:error, e)}
      send(MQTools.Provider.Dispatcher, {:reply, pack(reply), meta})
      reraise(e, stacktrace)
  end
end
