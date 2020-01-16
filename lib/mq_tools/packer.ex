defmodule MQTools.Packer do
  @callback pack(term) :: String.t()
  @callback unpack(String.t()) :: term

  def pack(term) do
    packer().pack(term)
  end

  def unpack(data) do
    packer().unpack(data)
  end

  defp packer do
    Application.get_env(:mq_provider, :packer, MQTools.JsonPacker)
  end
end

defmodule MQTools.JsonPacker do
  @behaviour MQTools.Packer

  def pack(term) do
    Jason.encode!(term)
  end

  def unpack(string) do
    Jason.decode!(string)
  end
end
