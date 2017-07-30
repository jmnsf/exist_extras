defmodule ExistExtras.Api do
  use Maru.Router

  require Logger

  @landing_page File.read! Path.join("views", "landing.mustache")
  @nutrition_page File.read! Path.join("views", "nutrition.mustache")

  plug Plug.Parsers,
    pass: ["*/*"],
    json_decoder: Poison,
    parsers: [:urlencoded, :json]

  plug ExistExtras.Api.Middleware.Authenticate

  desc "landing page"
  get do
    if !conn.assigns[:user_id] do
      landing_page = Mustachex.render @landing_page

      conn
      |> put_status(200)
      |> html(landing_page)
    else
      conn |> redirect("/nutrition")
    end
  end

  desc "nutrition page"
  params do
    optional :saved, type: Boolean
  end
  get :nutrition do
    cond do
      !conn.assigns[:user_id] -> conn |> redirect("/")
      !ExistExtras.Exist.authorized?(conn.assigns[:user_id]) -> conn |> redirect("/exist")
      true ->
        render_context = %{
          today: Date.to_string(Date.utc_today),
          saved: params[:saved] || [],
          attributes: ExistExtras.Exist.acquired_attributes(conn.assigns[:user_id])
        }

        home_page = Mustachex.render(@nutrition_page, render_context)

        conn
        |> put_status(200)
        |> html(home_page)
    end
  end

  namespace :google, do: mount ExistExtras.Api.Google
  namespace :exist, do: mount ExistExtras.Api.Exist

  namespace :css do
    route_param :file, type: String do
      desc "css files"
      get do
        neat_file = Regex.run(~r/(\w+\.css)/, params[:file], capture: :all_but_first)

        if File.exists?("css/#{neat_file}") do
          conn
          |> put_resp_header("content-type", "text/css")
          |> send_file(200, "css/#{neat_file}")
        else
          raise Maru.Exceptions.NotFound
        end
      end
    end
  end

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
