defmodule HttpServer do
  use Application.Behaviour

  def start, do: start([], [])
  def start(args), do: start([], args)
  def start(_type, args) do
    start_deps

    path = args[:path] || "/"
    port = args[:port] || 8080
    HttpServer.Handler.define_response(args[:response])

    dispatch = :cowboy_router.compile([
      {:_,
        [{path, HttpServer.Handler, []}]
      }
    ])
    :cowboy.start_http "my_http_listener_#{port}", 100,
        [{:port, port}], [{:env, [{:dispatch, dispatch}]}]

    HttpServer.Supervisor.start_link
  end

  defp start_deps do
    :application.start(:ranch)
    :application.start(:crypto)
    :application.start(:cowlib)
    :application.start(:cowboy)
  end

  def stop, do: stop(nil)
  def stop(_state) do
    :ok
  end
end
