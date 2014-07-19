defmodule HttpServer do
  use Application

  @listener_name "my_http_listener"
  @default_port 8080

  def start, do: start([], [])
  def start(args), do: start([], args)
  def start(_type, args) do
    path = args[:path] || "/"
    port = args[:port] || @default_port
    HttpServer.Handler.define_response(args[:response], args[:wait_time])

    dispatch = :cowboy_router.compile([
      {:_,
        [{path, HttpServer.Handler, []}]
      }
    ])
    :cowboy.start_http "#{@listener_name}_#{port}", 100,
        [{:port, port}], [{:env, [{:dispatch, dispatch}]}]

    HttpServer.Supervisor.start_link
  end

  def stop, do: stop(@default_port)
  def stop(port) do
    :cowboy.stop_listener("#{@listener_name}_#{port}")
  end
end
