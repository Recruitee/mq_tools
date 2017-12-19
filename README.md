# MQTools

Easily defined rabbitmq providers and client for "rpc" pattern - as described here: https://www.rabbitmq.com/tutorials/tutorial-six-elixir.html

This software is still in early beta version. Use at your own discretion.


## MQTools.Provider

Let's you define rabbitmq 'rpc endpoints'.

* Add `mq_tools` to dependencies in mix.exs
* Configure the module:

```
config :mq_tools, :mq_providers,
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
config :mq_tools, :mq_providers,
  rpc_providers: [MyRpcHandlers],
```

## MQTools.Client

Call previously defined providers. The one defined above could be called like so:

```
> MQTools.Client.call("foo.bar", %{something: "here"})
=> "reply..."
> MQTools.Client.call("foo.bar", %{different: "request"})
=> "handle other payload"
```

In case you just want to publish a message and you are not interested in the reply you can do the following:

```
> MQTools.Client.publish("foo.bar", %{something: "here"})
=> :ok
```

There is also optional client timeout param if you ever need it (default 10000ms):

```
> MQTools.Client.call("foo.bar", %{something: "here"}, 7500) # timeout in ms
=> "slow reply..."
```

## Optional message encoding configuration

By default the messages are transported using json. If you want to change that you can define your own message encoder/decoder module.

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
Orignally written by https://github.com/nilclass

## License

MQTools is released under the [MIT License](https://opensource.org/licenses/MIT).