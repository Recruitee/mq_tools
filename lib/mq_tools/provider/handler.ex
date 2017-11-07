defmodule MQTools.Provider.Handler do

  import MQTools.Packer, only: [pack: 1, unpack: 1]

  def start_link(module, queue, data, meta) do
    pid = spawn_link(__MODULE__, :run, [module, queue, data, meta])
    {:ok, pid}
  end

  def run(module, queue, data, meta) do
    reply = safe_call(module, queue, data)
    send(MQTools.Provider.Dispatcher, {:reply, pack(reply), meta})
  end

  defp safe_call(module, queue, data) do
    module.handle_rpc(queue, unpack(data))
  rescue
    e -> %{"error" => Exception.format(:error, e)}
  catch
    :exit, reason -> %{"error" => "Caught exit: #{inspect reason}"}
  end

end
