defmodule ExistExtras.Api.Cookies do
  import Plug.Conn

  require Logger

  @doc """
  Puts a `value` in the response cookies, signed, on the given `key`, with the
  defined `max_age`.
  """
  def put_signed(conn, key, value, max_age \\ 0) do
    hex_signature = generate_signature value
    encoded_value = Base.encode64 "#{value}|#{hex_signature}"

    Logger.debug(
      "[Cookies] Setting cookie: '#{key}' - '#{value}' - '#{hex_signature}' - #{encoded_value}"
    )

    conn
    |> put_resp_cookie(key, encoded_value, max_age: max_age)
  end

  @doc """
  Retrieves and verifies a signed cookie from the connection at the given `key`.
  """
  def get_signed(conn, key) do
    conn = fetch_cookies conn

    with encoded_value <- conn.req_cookies[key],
         {:ok, decoded} <- Base.decode64(encoded_value || ""),
         [value, signature] <- String.split(decoded, "|"),
         ^signature <- generate_signature(value)
    do
      value
    else
      _ -> nil
    end
  end

  defp generate_signature(value) do
    :crypto.hmac(:sha512, sign_key(), value) |> Base.encode16()
  end

  defp sign_key do
    case ExistExtras.fetch_config!(:exist_extras, ExistExtras.Api.Cookies, :sign_key) do
      nil -> throw "Cookie signature key is nil!"
      "" -> throw "Cookie signature key is empty!"
      key -> key
    end
  end
end
