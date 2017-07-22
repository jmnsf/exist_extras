defmodule ExistExtras.Api.Google do
  use Maru.Router

  alias ExistExtras.Google.OAuth, as: GoogleOAuth

  desc "authenticates with google"
  get do
    scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/fitness.nutrition.read"
    ]

    conn
    |> redirect(GoogleOAuth.build_authorize_url(scopes))
  end

  desc "Google OAuth callback endpoint"
  params do
    requires :state, type: String
    requires :code, type: String
  end
  get :oauth do
    if GoogleOAuth.state_valid?(params[:state]) do
      user_id = GoogleOAuth.authorize(params[:code])

      if !user_id do
        conn
        |> put_status(401)
        |> text("Not Authorized")
      else
        conn
        |> ExistExtras.Api.Cookies.put_signed("user_id", user_id, 31_536_000)
        |> redirect("/exist")
      end
    else
      conn
      |> put_status(403)
      |> text("Bad state")
    end
  end
end
