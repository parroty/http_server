defmodule HttpServerTest do
  use ExUnit.Case

  setup_all do
    HTTPotion.start
  end

  test "default server response" do
    HttpServer.start
    response = HTTPotion.get("http://localhost:8080")
    assert(response.body == "Hello World")
  end

  test "custom server response" do
    HttpServer.start(path: "/test", port: 4000, response: "Custom Response")
    response = HTTPotion.get("http://localhost:4000/test")
    assert(response.body == "Custom Response")
  end

  test "getting response takes the specified wait_time" do
    HttpServer.start(path: "/test", port: 4001,
                     response: "Custom Response", wait_time: 1000) # 1.0 sec

    s = :erlang.now
    response = HTTPotion.get("http://localhost:4001/test")
    e = :erlang.now
    assert(response.body == "Custom Response")
    assert(:timer.now_diff(e, s) >= 800_000)  # 0.8 sec
  end
end
