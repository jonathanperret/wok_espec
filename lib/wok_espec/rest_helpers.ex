defmodule WokEspec.RESTHelpers do

  @stubbed_http_req :stubbed_http_req

  def wok_post(route, body, headers) do
    make_call(route, [], body, headers, :post)
  end

  def wok_delete(route, headers) do
    make_call(route, [], "{}", headers, :delete)
  end

  def wok_get(route, params \\ [], headers) do
    make_call(route, params, "{}", headers, :get)
  end

  def wok_patch(route, params \\[] , body, headers ) do
    make_call(route, params, body, headers, :patch)
  end


  defp call_http(route, params, body , headers, method) do
    url_route = replace_symbols_by_values(route, params)
    base_url = "http://localhost:#{Application.get_env(:wok, :rest)[:port]}"
    case method do
      :post -> HTTPoison.post!("#{base_url}#{url_route}", body, headers)
      :delete -> HTTPoison.delete!("#{base_url}#{url_route}", headers)
      :get -> HTTPoison.get!("#{base_url}#{url_route}", headers)
      :patch -> HTTPoison.patch!("#{base_url}#{url_route}", body, headers)
    end
  end

  defp make_call(route, params, body , headers, method) do
    case System.get_env("HTTP_TEST") do
      "true" ->
        call_http(route, params, body, headers, method)
      _ ->
        route_ch = build_route_url(route, params) |> String.to_char_list
        rest_verb = method |> Atom.to_string |> String.upcase |> String.to_atom
        {_,_,{module, method}} = Application.get_env(:wok, :rest)[:routes]
        |> Enum.find(fn el ->
          case el do
            {^rest_verb, ^route_ch, _} -> true
            _ -> false
          end
        end)
        start_meck(:cowboy_req)

        stub_body(@stubbed_http_req, body)
        stub_headers(@stubbed_http_req, headers)
        stub_params(@stubbed_http_req, params)
        {status_code, headers, body, state} = apply(module, method, [@stubbed_http_req, %{}] )

        :meck.unload(:cowboy_req)
        %{status_code: status_code, headers: headers, body: body, state: state}
    end
  end

  defp stub_body(request, body) do
    :meck.expect(:cowboy_req, :body, fn(^request) ->
      {:ok, body, request}
    end)
  end

  def stub_params(request, params) do
    :meck.expect(:cowboy_req, :binding, fn(param, ^request) ->
      case Dict.get(params, param) do
        int when is_integer(int) -> int |> Integer.to_string
        str -> str
      end
    end)
  end

  defp stub_headers(request, headers) do
    :meck.expect :cowboy_req, :header, fn(header_key, ^request, "") ->
      headers
      |> Enum.find({}, fn({key, _}) -> header_key == key end)
      |> Tuple.to_list
      |> Enum.join(" ")
    end
  end

  defp start_meck(module) do
    try do
      :meck.new(module, [:non_strict, :passthrough])
    rescue
      error in [ErlangError] ->
        case error do
          %ErlangError{original: {:already_started, _pid}} -> :ok
          _ -> raise error
        end
    end
  end

  defp build_route_url(route, params) do
    suffix = params |> Enum.map(fn({key, _}) -> ":#{Atom.to_string(key)}" end) |> Enum.join("/")
    case suffix do
      "" -> route
      suffix -> "#{route}/#{suffix}"
    end
  end

  defp replace_symbols_by_values(route, params) do
    route_url = build_route_url(route, params)
    params |> Enum.reduce(route_url, fn({key, value},acc) ->
      String.replace(acc,":#{Atom.to_string(key)}",to_string(value))
    end)
  end
end
