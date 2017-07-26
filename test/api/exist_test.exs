defmodule ExistExtras.Api.ExistTest do
  use ExUnit.Case, async: true
  use Maru.Test

  import ExistExtras.ApiUtils

  @moduletag :api

  describe "GET /exist" do
    test "redirects to landing page if not logged in" do
      response = get("/exist")

      assert response.status == 302
      [location] = Plug.Conn.get_resp_header(response, "location")
      assert location == "/"
    end

    test "redirects to Exist's OAuth page" do
      response =
        auth_conn("1234")
        |> get("/exist")

      assert response.status == 302

      [location] = Plug.Conn.get_resp_header(response, "location")
      assert location =~ ExistExtras.Exist.OAuth.authorization_endpoint()
    end
  end

  describe "GET /exist/oauth" do
    test "redirects to root when not logged in" do
      response = get("/exist/oauth?code=1234567890")

      assert response.status == 302
      [location] = Plug.Conn.get_resp_header(response, "location")
      assert location == "/"
    end

    # see sync tests
  end

  describe "POST /exist/nutrition" do
    test "redirects to root when not logged in" do
      response =
        build_conn()
        |> put_body_or_params(%{date: "2017-07-26", calories: 9001})
        |> post("/exist/nutrition")

      assert response.status == 302
      [location] = Plug.Conn.get_resp_header(response, "location")
      assert location == "/"
    end

    # see sync tests
  end

  describe "POST /exist/attributes/acquire" do
    test "redirects to root when not logged in" do
      response = post("/exist/attributes/acquire")

      assert response.status == 302
      [location] = Plug.Conn.get_resp_header(response, "location")
      assert location == "/"
    end

    # see sync tests
  end
end

defmodule ExistExtras.Api.ExistTestSync do
  use ExUnit.Case, async: false
  use Maru.Test
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import ExistExtras.ApiUtils

  setup_all do
    ExVCR.Config.cassette_library_dir "fixtures/vcr_cassettes/exist"
    :ok
  end

  @moduletag :api

  describe "GET /exist/oauth" do
    test "redirects to the nutrition page" do
      use_cassette "oauth_authorize", match_requests_on: [:request_body, :query] do
        response =
          auth_conn("1234")
          |> get("/exist/oauth?code=some-code")

        [location] = Plug.Conn.get_resp_header(response, "location")

        assert response.status == 302
        assert location == "/nutrition"
      end
    end

    test "authorizes the received code, saves the tokens and acquires attribute ownership" do
      use_cassette "oauth_authorize", match_requests_on: [:request_body, :query] do
        response =
          auth_conn("1234")
          |> get("/exist/oauth?code=some-code")

        assert response.status == 302

        assert Redix.command!(
          ExistExtras.Redis.redis_connection!(),
          ~w(TTL exist:access_tokens:1234)
        ) == 31535999
      end
    end
  end

  describe "POST /exist/nutrition" do
    test "posts the given nutrition data to Exist with the right conversions" do
      use_cassette "save_nutrition", match_requests_on: [:request_body] do
        body = %{
          date: "2017-07-26",
          calories: 2578,
          carbs: 65,
          protein: 167,
          fat: 179,
          fiber: 28,
          sugar: 24,
          sodium: 1108,
          cholesterol: 138
        }

        response =
          auth_conn("1234")
          |> put_body_or_params(body)
          |> post("/exist/nutrition")

        assert response.status == 302

        [location] = Plug.Conn.get_resp_header(response, "location")
        assert location == "/nutrition?saved=true"
      end
    end
  end

  describe "POST /exist/attributes/acquire" do
    test "re-acquires attributes from Exist" do
      use_cassette "acquire_attribute_ownership", match_requests_on: [:request_body] do
        response =
          auth_conn("1234")
          |> post("/exist/attributes/acquire")

        assert response.status == 302
        [location] = Plug.Conn.get_resp_header(response, "location")
        assert location == "/nutrition"
      end
    end
  end
end
