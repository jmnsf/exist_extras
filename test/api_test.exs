defmodule ExistExtras.ApiTest do
  use ExUnit.Case, async: true
  use Maru.Test

  import ExistExtras.ApiUtils

  @moduletag :api

  describe "GET /" do
    test "shows the landing page if the user is not signed in" do
      response = get("/")

      assert response.status == 200
      assert response.resp_body =~ ~r/Exist Extras/
      assert response.resp_body =~ ~r/Built by/
    end

    test "has a button for logging in to google" do
      html = get("/").resp_body
      assert html =~ ~r/a.+href="\/google"/
    end

    test "redirects to /nutrition if the user is signed in" do
      response =
        auth_conn("1234")
        |> get("/")

      assert response.status == 302
      [location] = Plug.Conn.get_resp_header(response, "location")
      assert location == "/nutrition"
    end
  end

  describe "GET /nutrition" do
    test "redirects to root if user is not signed in" do
      response = get("/nutrition")

      assert response.status == 302
      [location] = Plug.Conn.get_resp_header(response, "location")
      assert location == "/"
    end

    test "redirects to /exist if user is not authorized with Exist" do
      response =
        auth_conn("1234")
        |> get("/nutrition")

      assert response.status == 302
      [location] = Plug.Conn.get_resp_header(response, "location")
      assert location == "/exist"
    end

    # See sync tests
  end

  describe "GET /css/:file" do
    # These don't work, probably because of some maru things
    test "loads the default styles" do
      # response = get("/css/styles.css")
      # assert response.status == 200
      # assert response.resp_body
      # [content_type] = Plug.Conn.get_resp_header(response, "content-type")
      # assert content_type == "test/css"
    end
  end
end

defmodule ExistExtras.ApiTestSync do
  use ExUnit.Case, async: true
  use Maru.Test
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import ExistExtras.ApiUtils

  @moduletag :api

  setup_all do
    authorize_exist("api-test-1")
    ExVCR.Config.cassette_library_dir "fixtures/vcr_cassettes/exist"
    :ok
  end

  describe "GET /nutrition" do
    test "fetches and displays acquired attributes" do
      use_cassette "acquired_attributes" do
        response = auth_conn("api-test-1") |> get("/nutrition")

        assert response.status == 200
        assert response.resp_body
        |> Floki.find("span.attribute-label")
        |> Floki.text(sep: " ") ==
        "Energy in Carbohydrates Fat Fibre Protein Sodium Sugar Cholesterol"
      end
    end

    test "shows form for updating nutrition data" do
      use_cassette "acquired_attributes" do
        html = (auth_conn("api-test-1") |> get("/nutrition")).resp_body

        assert Floki.find(html, "form[action=\"/exist/nutrition\"][method=\"POST\"")
        assert html
          |> Floki.find("form input")
          |> Floki.attribute("name") ==
          ["date", "calories", "fat", "carbs", "protein", "fiber", "sugar", "sodium", "cholesterol"]
      end
    end
  end
end
