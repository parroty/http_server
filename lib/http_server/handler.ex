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
    {range_header, req} = :cowboy_req.header("range", req)
    {response, wait_time} = :ets.lookup(@ets_table, @ets_key)[@ets_key]
    wait_for(wait_time)
    case response do
      {status, headers, body} ->
        {status, headers, body} = apply_byte_range({status, headers, body}, range_header)
        {:ok, req} = :cowboy_req.reply status, headers, body, req
      response ->
        if is_function(response) do
          {status, headers, body} =
            response.(req_values(req))
            |> apply_byte_range(range_header)
          {:ok, req} = :cowboy_req.reply status, headers, body, req
        else
          {status, headers, body} = apply_byte_range({200, [], response}, range_header)
          {:ok, req} = :cowboy_req.reply status, headers, body, req
        end
    end
    {:ok, req, state}
  end

  defp normalize_byte_range(body, range_str) do
    if range_str == :undefined do
      nil
    else
      case parse_byte_range(range_str) do
        nil -> nil
        {:error, {:unexpected_range_header_format, _}} -> nil
        {first, nil} ->
          first..byte_size(body)
        {first, last} ->
          first..last
      end
    end
  end

  defp apply_byte_range({status, headers, body}, range_str) do
    case normalize_byte_range(body, range_str) do
      nil -> {status, headers, body}
      first..last ->
        new_body = Enum.slice(:erlang.binary_to_list(body), first..(last - 1)) |> :erlang.list_to_binary
        new_headers = [{"Content-Range", "#{first}-#{last}"} | headers]
        new_status = if status == 200, do: 206, else: status
        {new_status, new_headers, new_body}
    end
  end

  defp parse_byte_range(range_str) do
    case Regex.run(~r/bytes=(\d+)-(\d*)/i, range_str) do
      [_, first_str, last_str] ->
        {first, _} = Integer.parse(first_str)
        last =
          if last_str == "" do
            nil
          else
            {last, _} = Integer.parse(last_str)
            last
          end
        {first, last}
      nil -> {:error, {:unexpected_range_header_format, "expected \"Range: bytes=start-end\""}}
    end
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

    headers = Enum.map(headers, fn({k, v}) -> {String.to_atom(k), v} end)
    query_params = Enum.map(query_params, fn({k, v}) -> {String.to_atom(k), v} end)
    post_params = Enum.map(post_params, fn({k, v}) -> {String.to_atom(k), v} end)

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
