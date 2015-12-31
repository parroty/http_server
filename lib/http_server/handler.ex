defmodule HttpServer.Handler do
  @moduledoc """
  Provides handler for cowboy
  """
  @ets_table :httpserver_handler
  @ets_key   :response
  @default_response "Hello World"

  def define_response(response, wait_time) do
    response  = response || @default_response
    wait_time = wait_time || 0

    if :ets.info(@ets_table) == :undefined do
      :ets.new(@ets_table, [:set, :public, :named_table])
    end
    :ets.insert(@ets_table, {@ets_key, {response, wait_time}})
  end

  def init({_any, :http}, req, []) do
    {:ok, req, :undefined}
  end

  def handle(req, state) do
    {response, wait_time} = :ets.lookup(@ets_table, @ets_key)[@ets_key]
    wait_for(wait_time)
    case response do
      {status, headers, body} ->
        {:ok, req} = :cowboy_req.reply status, headers, body, req
      response ->
        if is_function(response) do
          {status, headers, body} = response.(req_values(req))
          {:ok, req} = :cowboy_req.reply status, headers, body, req
        else
          {:ok, req} = :cowboy_req.reply 200, [], response, req
        end
    end
    {:ok, req, state}
  end

  defp wait_for(duration) do
    if duration > 0 do
      current_pid = self
      spawn fn ->
        :timer.sleep(duration)
        send current_pid, :completed
      end

      receive do
        :completed -> nil  # do nothing
      end
    end
  end

  # Parse the cowboy request into something that's easy to pull values out of.
  defp req_values(req) do
    {headers, _} = :cowboy_req.headers(req)
    {query_params, _} = :cowboy_req.qs_vals(req)
    {:ok, body, _} = :cowboy_req.body(req)
    {host, _} = :cowboy_req.host(req)
    {:ok, post_params, _} = :cowboy_req.body_qs(req)
    {port, _} = :cowboy_req.port(req)
    {method, _} = :cowboy_req.method(req)

    %{
      method: method,
      host: host,
      port: port,
      headers: headers,
      query_params: query_params,
      post_params: post_params,
      body: body,
      req: req
    }
  end

  def terminate(_reason, _request, _state) do
    :ok
  end
end
