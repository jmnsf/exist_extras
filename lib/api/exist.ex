defmodule ExistExtras.Api.Exist do
  use Maru.Router

  alias ExistExtras.Exist.OAuth, as: ExistOAuth
  alias ExistExtras.Exist

  desc "authenticates with Exist"
  get do
    if !conn.assigns[:user_id] do
      conn |> redirect("/")
    else
      conn |> redirect(ExistOAuth.build_authorize_url())
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
      :ok = Exist.acquire_attribute_ownership conn.assigns[:user_id]

      conn |> redirect("/nutrition")
    end
  end

  desc "Send nutrition data to Exist"
  params do
    requires :calories, type: Integer
    requires :date, type: Date
    optional :carbs, type: Float
    optional :fiber, type: Float
    optional :protein, type: Float
    optional :fat, type: Float
    optional :sugar, type: Float
    optional :sodium, type: Float
    optional :cholesterol, type: Float
  end
  post :nutrition do
    if !conn.assigns[:user_id] do
      conn |> redirect("/")
    else
      :ok = Exist.save_nutrition(conn.assigns[:user_id], params[:date], extract_nutrition(params))

      conn |> redirect("/nutrition?saved=true")
    end
  end

  namespace :attributes do
    desc "Re-acquire attributes in Exist"
    post :acquire do
      if !conn.assigns[:user_id] do
        conn |> redirect("/")
      else
        :ok = Exist.acquire_attribute_ownership conn.assigns[:user_id]
        conn |> redirect("/nutrition")
      end
    end
  end

  defp extract_nutrition(params) do
    params
    |> Map.keys()
    |> Enum.filter_map(
      fn key -> key != :date end,
      fn key ->
        case key do
          :calories -> {:energy, params[:calories] * 4.184}
          :carbs -> {:carbohydrates, params[:carbs]}
          :fiber -> {:fibre, params[:fiber]} # notice change in spelling!
          _ -> {key, params[key]}
        end
      end
    )
  end
end
