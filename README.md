# MQTools.Provider

Easy way to define rabbitmq based rpc providers.

## Usage

* Add `mq_provider` to dependencies in mix.exs
* Add `mq_provider` to extra_applications in mix.exs

* Configure the module:

```
config :mq_tools, :mq_providers,
  rpc_providers: [],
  connection: [
    host: "localhost",
    port: 5672,
    virtual_host: "/",
    user: "guest",
    password: "guest"
  ]
```

* Write a module defining RPC handlers:

```
defmodule MyRpcHandlers do
  use MQTools.Provider

  defprc "foo.bar" do
    %{"something" => something} -> "reply..."
    _ -> "handle other payload"
  end
end
```

and add the module to the config:

```
  rpc_providers: [MyRpcHandlers],
```

## Optional message encoding configuration

By default the messages are transported as json. If you want to change that you can define your own message encoder/decoder module.

```
defmodule MyOwnMsgPacker do
  @behaviour MQTools.Packer

  def pack(term) do
    SuperPackLib.pack(term)
  end

  def unpack(string) do
    SuperPackLib.unpack(string)
  end

end
```

and set it in the config as your packer module:

```
config :mq_provider,
  packer: MyOwnMsgPacker
````


## Kudos
Orignally written by: https://github.com/nilclass

## License

Ruby on Rails is released under the [MIT License](https://opensource.org/licenses/MIT).