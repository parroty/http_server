defmodule HttpServer.Handler do
  @moduledoc """
  Provides handler for cowboy
  """
  @ets_table :httpserver_handler
  @ets_key   :response
  @default_response "Hello World"

  def define_response(response) do
    response = response || @default_response
    if :ets.info(@ets_table) == :undefined do
      :ets.new(@ets_table, [:set, :public, :named_table])
    end
    :ets.insert(@ets_table, {@ets_key, response})
  end

  def init({_any, :http}, req, []) do
    {:ok, req, :undefined}
  end

  def handle(req, state) do
    response = :ets.lookup(@ets_table, @ets_key)[@ets_key]
    {:ok, req} = :cowboy_req.reply 200, [], response, req
    {:ok, req, state}
  end

  def terminate(_reason, _request, _state) do
    :ok
  end
end
