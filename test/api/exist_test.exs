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
end

defmodule ExistExtras.Api.ExistTestSync do
  use ExUnit.Case, async: false
  use Maru.Test
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import ExistExtras.ApiUtils

  setup_all do
    ExVCR.Config.cassette_library_dir "fixtures/vcr_cassettes"
    :ok
  end

  @moduletag :api

  describe "GET /exist/oauth" do
    test "redirects to home Exist" do
      use_cassette "exist_authorize_code" do
        response =
          auth_conn("1234")
          |> get("/exist/oauth?code=some-code")

        [location] = Plug.Conn.get_resp_header(response, "location")

        assert response.status == 302
        assert location == "/home"
      end
    end

    test "authorizes the received code and saves the tokens" do
      use_cassette "exist_authorize_code" do
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
end
