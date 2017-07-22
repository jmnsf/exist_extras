defmodule ExistExtras.Api.Exist do
  use Maru.Router

  alias ExistExtras.Exist.OAuth, as: ExistOAuth

  desc "authenticates with Exist"
  get do
    if !conn.assigns[:user_id] do
      conn |> redirect("/")
    else
      conn
      |> redirect(ExistOAuth.build_authorize_url())
    end
  end

  desc "Exist OAuth callback endpoint"
  params do
    requires :code, type: String
  end
  get :oauth do
    if !conn.assigns[:user_id] do
      conn |> redirect("/")
    else
      :ok = ExistOAuth.authorize conn.assigns[:user_id], params[:code]

      conn
      |> redirect("/home")
    end
  end
end
