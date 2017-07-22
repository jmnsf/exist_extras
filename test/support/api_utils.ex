defmodule ExistExtras.ApiUtils do
  require Plug.Conn

  @doc """
  Builds a connection where the user is authenticated, i.e., there's a signed
  cookie with the user's ID.
  """
  def auth_conn(user_id) do
    conn = ExistExtras.Api.Cookies.put_signed(%Plug.Conn{}, "user_id", user_id)
    struct(conn, req_cookies: %{"user_id" => conn.resp_cookies["user_id"][:value]})
  end
end
