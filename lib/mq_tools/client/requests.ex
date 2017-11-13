defmodule MQTools.Client.Requests do

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(name) do
    Agent.get(__MODULE__, fn map -> Map.get(map, name) end )
  end

  def delete(name) do
    Agent.update(__MODULE__, fn map -> Map.delete(map, name) end )
  end

  def put(name, handler) do
    Agent.update(__MODULE__, fn map -> Map.put(map, name, handler) end )
  end

end
