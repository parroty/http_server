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
      headers: ["X-Test-Header": "My-Value"],
    ])
    assert(response.body == "Accepted")
    assert(response.status_code == 202)
    assert(response.headers[:"X-Custom"] == "My-Dynamic-Header")
  end
end
