defmodule HttpServerTest do
  use ExUnit.Case

  setup_all do
    HTTPotion.start
    :ok
  end

  test "default server response" do
    HttpServer.start
    response = HTTPotion.get("http://localhost:8080")
    assert(response.body == "Hello World")
    HttpServer.stop
  end

  test "custom server response" do
    HttpServer.start(path: "/test", port: 4000, response: "Custom Response")
    response = HTTPotion.get("http://localhost:4000/test")
    assert(response.body == "Custom Response")
    HttpServer.stop(4000)
  end

  test "getting response takes the specified wait_time" do
    HttpServer.start(path: "/test", port: 4001,
                     response: "Custom Response", wait_time: 1000) # 1.0 sec

    s = :os.timestamp
    response = HTTPotion.get("http://localhost:4001/test")
    e = :os.timestamp
    assert(response.body == "Custom Response")
    assert(:timer.now_diff(e, s) >= 800_000)  # 0.8 sec
    HttpServer.stop(4001)
  end

  test "custom status code and headers" do
    HttpServer.start(
      path: "/test",
      port: 4000,
      response: {201, [{"X-Custom", "My-Header"}], "Created"}
    )

    response = HTTPotion.get("http://localhost:4000/test")
    assert(response.body == "Created")
    assert(response.status_code == 201)
    assert(response.headers[:"X-Custom"] == "My-Header")
    HttpServer.stop(4000)
  end

  test "custom function" do
    HttpServer.start(
      path: "/test",
      port: 4000,
      response: fn(req) ->
        assert req.headers[:"x-test-header"] == "My-Value"
        assert req.host == "localhost"
        assert req.query_params[:foo] == "bar"
        assert req.query_params[:abc] == "def"
        assert req.post_params[:body] == "param"
        assert req.body == "body=param"
        {"localhost", _} = :cowboy_req.host(req.req)
        {202, [{"X-Custom", "My-Dynamic-Header"}], "Accepted"}
      end
    )

    response = HTTPotion.post("http://localhost:4000/test?foo=bar&abc=def", [
      body: "body=param",
      headers: ["X-Test-Header": "My-Value", "Content-Type": "x-www-form-urlencoded"],
    ])
    assert(response.body == "Accepted")
    assert(response.status_code == 202)
    assert(response.headers[:"X-Custom"] == "My-Dynamic-Header")
    HttpServer.stop(4000)
  end

  test "json" do
    HttpServer.start(
      path: "/test",
      port: 4000,
      response: fn(req) ->
        {200, [], req.body}
      end
    )

    json =
      (0..100_000)
      |> Enum.map(fn(n) -> "\"hello#{n}\": \"world\"" end)
      |> Enum.join(", ")
      |> (&("{#{&1}}")).()

    response = HTTPotion.post("http://localhost:4000/test", [
      body: json,
      headers: ["X-Test-Header": "My-Value", "Content-Type": "application/json"],
    ])

    assert(response.body == json)
    HttpServer.stop(4000)
  end

  test "range request" do
    HttpServer.start(path: "/", port: 4000, response: "Custom Response")

    response = HTTPotion.get("http://localhost:4000", headers: ["Range": "bytes=2-5"])
    assert(response.headers[:"Content-Range"] == "2-5")
    assert(response.body == "sto")

    response = HTTPotion.get("http://localhost:4000", headers: ["Range": "bytes=12-15"])
    assert(response.headers[:"Content-Range"] == "12-15")
    assert(response.body == "nse")

    response = HTTPotion.get("http://localhost:4000", headers: ["Range": "bytes=0-"])
    assert(response.headers[:"Content-Range"] == "0-15")
    assert(response.body == "Custom Response")

    # In case someone wants to implement their own special range header
    # functionality, don't fail if it's not a valid byte range request.
    response = HTTPotion.get("http://localhost:4000", headers: ["Range": "invalid"])
    assert(response.headers[:"Content-Range"] == nil)
    assert(response.body == "Custom Response")

    HttpServer.stop(4000)
  end
end
