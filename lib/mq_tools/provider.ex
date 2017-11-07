defmodule MQTools.Provider do
  defmacro __using__(_) do
    quote do
      @rpc_names []
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def rpc_names, do: @rpc_names
    end
  end

  defmacro defrpc(name, do: block) do
    quote do
      @rpc_names [unquote(name) | @rpc_names]
      def handle_rpc(unquote(name), req) do
        case req, do: unquote(block)
      end
    end
  end
end
