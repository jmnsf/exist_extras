defmodule ExistExtras.Api.Middleware.Authenticate do
  use Maru.Middleware

  def call(conn, _opts) do
    case ExistExtras.Api.Cookies.get_signed(conn, "user_id") do
      user_id when not is_nil(user_id) -> assign(conn, :user_id, user_id)
      _ -> conn
    end
  end
end
