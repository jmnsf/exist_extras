defmodule ExistExtras.Exist.OAuthTest do
  use ExUnit.Case, async: true

  alias ExistExtras.Exist.OAuth

  describe "build_authorize_url/1" do
    test "returns a standard OAuth authorize URL" do
      url = OAuth.build_authorize_url()
      [host, query_string] = String.split(url, "?")

      assert host == "https://exist.io/oauth2/authorize"
      %{
        "client_id" => "existClientId",
        "redirect_uri" => "http://localhost/exist/oauth",
        "response_type" => "code"
      } = URI.decode_query(query_string)
    end

    test "includes the passed scopes, space separated" do
      q = OAuth.build_authorize_url()
      |> String.split("?")
      |> Enum.at(1)
      |> URI.decode_query()

      assert q["scope"] == "read+write"
    end
  end

  describe "save_access_token/3" do
    test "persists the given access token assigned to the given user_id" do
      OAuth.save_access_token "some-id", "some-token", 15

      assert Redix.command!(
        ExistExtras.Redis.redis_connection!(),
        ~w(GET exist:access_tokens:some-id)
      ) == "some-token"
    end

    test "expires the token after the given expires_in" do
      OAuth.save_access_token "some-id", "some-token", 15

      ttl = Redix.command!(
        ExistExtras.Redis.redis_connection!(),
        ~w(TTL exist:access_tokens:some-id)
      )

      assert ttl > 12
      assert ttl <= 15
    end
  end

  describe "save_refresh_token/2" do
    test "persists the given access token assigned to the given user_id" do
      OAuth.save_refresh_token "some-id", "some-token"

      assert Redix.command!(
        ExistExtras.Redis.redis_connection!(),
        ~w(GET exist:refresh_tokens:some-id)
      ) == "some-token"
    end

    test "adds the user_id to the User IDs set" do
      OAuth.save_refresh_token "some-id", "some-token"

      assert Redix.command!(
        ExistExtras.Redis.redis_connection!(),
        ~w(SMEMBERS exist:user_ids)
      ) == ["some-id"]
    end
  end

  describe "authorization_endpoint/0" do
    test "returns Exist's authorization_endpoint" do
      assert OAuth.authorization_endpoint() == "https://exist.io/oauth2/authorize"
    end
  end

  describe "token_endpoint/0" do
    test "returns Exist's token_endpoint" do
      assert OAuth.token_endpoint() == "https://exist.io/oauth2/access_token"
    end
  end
end

defmodule ExistExtras.Exist.OAuthTestSync do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    ExVCR.Config.cassette_library_dir "fixtures/vcr_cassettes/exist"
    :ok
  end

  alias ExistExtras.Exist.OAuth

  describe "authorize/2" do
    test "uses the given code to authorize the user with Exist" do
      use_cassette "exist_authorize_code" do
        :ok = OAuth.authorize("a-user-id", "some-code")
      end
    end

    test "persists the received access & refresh tokens" do
      use_cassette "exist_authorize_code" do
        redis = ExistExtras.Redis.redis_connection!()

        :ok = OAuth.authorize("a-user-id", "some-code")

        [user_ids, at, ttl, rt] = Redix.pipeline!(redis, [
          ~w(SMEMBERS exist:user_ids),
          ~w(GET exist:access_tokens:a-user-id),
          ~w(TTL exist:access_tokens:a-user-id),
          ~w(GET exist:refresh_tokens:a-user-id)
        ])

        assert Enum.any?(user_ids, fn val -> val == "a-user-id" end)
        assert at == "an-access-token"
        assert ttl == 31535999
        assert rt == "a-refresh-token"
      end
    end
  end
end
