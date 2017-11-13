defmodule MQTools.Packer do
  @callback pack(term) :: String.t
  @callback unpack(String.t) :: term

  def pack(term) do
    packer().pack(term)
  end

  def unpack(data) do
    packer().unpack(data)
  end

  defp packer do
    case Application.fetch_env(:mq_provider, :packer) do
      :error -> MQTools.JsonPacker
      packer -> packer
    end
  end

end

defmodule MQTools.JsonPacker do
  @behaviour MQTools.Packer

  def pack(term) do
    Poison.encode!(term)
  end

  def unpack(string) do
    Poison.decode!(string)
  end
end