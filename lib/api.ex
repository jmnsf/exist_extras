defmodule ExistExtras.Api do
  use Maru.Router

  require Logger

  plug Plug.Parsers,
    pass: ["*/*"],
    parsers: [:urlencoded, :json]

  plug ExistExtras.Api.Middleware.Authenticate

  desc "landing page"
  get do
    if !conn.assigns[:user_id] do
      landing_page = Mustache.render(File.read!("views/landing.mustache"))

      conn
      |> put_status(200)
      |> html(landing_page)
    else
      conn |> redirect("/home")
    end
  end

  desc "home page"
  get :home do
    cond do
      !conn.assigns[:user_id] -> conn |> redirect("/")
      !ExistExtras.Exist.authorized?(conn.assigns[:user_id]) -> conn |> redirect("/exist")
      true ->
        home_page = Mustache.render(
          File.read!("views/home.mustache"), %{today: Date.to_string(Date.utc_today)}
        )

        conn
        |> put_status(200)
        |> html(home_page)
    end
  end

  namespace :google, do: mount ExistExtras.Api.Google
  namespace :exist, do: mount ExistExtras.Api.Exist

  rescue_from Maru.Exceptions.NotFound do
    conn
    |> put_status(404)
    |> text("Not Found")
  end

  rescue_from :all, as: e do
    Logger.error "[Router] Caught Server Error #{Exception.format(:error, e)}. Returning 500."

    conn
    |> put_status(500)
    |> text("Server Error")
  end
end
