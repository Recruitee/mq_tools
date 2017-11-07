defmodule MQTools.Provider.HandlerSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    supervise([worker(MQTools.Provider.Handler, [], [restart: :temporary])], strategy: :simple_one_for_one)
  end

  def spawn_handler(args) do
    Supervisor.start_child(__MODULE__, args)
  end
end
