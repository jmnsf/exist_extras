defmodule ExistExtras.Api.GoogleTest do
  use ExUnit.Case, async: true
  use Maru.Test

  @moduletag :api

  setup_all do
    Redix.command!(
      ExistExtras.Redis.redis_connection!(),
      ["SET" | ["cache:google:discovery_doc" | [File.read!("fixtures/google_discovery_doc.json") | []]]]
    )

    :ok
  end

  describe "GET /google" do
    test "redirects to Google's OAuth page" do
      response = get("/google")

      assert response.status == 302

      [location] = Plug.Conn.get_resp_header(response, "location")
      assert location =~ ExistExtras.Google.OAuth.authorization_endpoint()
    end
  end

  describe "GET /google/oauth" do
    test "rejects a bad state with 403" do
      response = get("/google/oauth?state=balelas&code=1234567890")

      assert response.status == 403
      assert response.resp_body == "Bad state"
    end

    # see sync tests
  end
end

defmodule ExistExtras.Api.GoogleTestSync do
  use ExUnit.Case, async: false
  use Maru.Test

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    ExVCR.Config.cassette_library_dir "fixtures/vcr_cassettes"
    :ok
  end

  @moduletag :api

  describe "GET /google/oauth" do
    test "authorizes the received code and saves the tokens" do
      use_cassette "google_authorize_code" do
        state = ExistExtras.Google.OAuth.generate_state()
        response = get("/google/oauth?code=a-noice-code&state=#{state}")

        assert response.status == 302

        assert Redix.command!(
          ExistExtras.Redis.redis_connection!(),
          ~w(TTL google:access_tokens:105080967267504390361)
        ) == 3600
      end
    end

    test "saves the received user_id in an encoded cookie and redirects to Exist" do
      use_cassette "google_authorize_code" do
        state = ExistExtras.Google.OAuth.generate_state()
        response = get("/google/oauth?code=a-noice-code&state=#{state}")
        [location] = Plug.Conn.get_resp_header(response, "location")
        %{"user_id" => user_id} = response.resp_cookies

        assert location == "/exist"
        assert user_id
      end
    end
  end
end
