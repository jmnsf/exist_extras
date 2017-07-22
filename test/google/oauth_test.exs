defmodule ExistExtras.Google.OauthTest do
  use ExUnit.Case, async: true

  alias ExistExtras.Google.OAuth

  setup_all do
    Redix.command!(
      ExistExtras.Redis.redis_connection!(),
      ["SET" | ["cache:google:discovery_doc" | [File.read!("fixtures/google_discovery_doc.json") | []]]]
    )

    :ok
  end

  describe "build_authorize_url/1" do
    test "returns a standard OAuth authorize URL" do
      url = OAuth.build_authorize_url([])
      [host, query_string] = String.split(url, "?")

      assert host == "https://accounts.google.com/o/oauth2/v2/auth"
      %{
        "client_id" => "googleClientId",
        "redirect_uri" => "http://localhost/google/oauth",
        "response_type" => "code",
        "access_type" => "offline",
        "prompt" => "consent"
      } = URI.decode_query(query_string)
    end

    test "includes a random state" do
      q = OAuth.build_authorize_url([])
      |> String.split("?")
      |> Enum.at(1)
      |> URI.decode_query()

      assert q["state"]
    end

    test "includes the passed scopes, space separated" do
      q = OAuth.build_authorize_url(["one-scope", "two-scope"])
      |> String.split("?")
      |> Enum.at(1)
      |> URI.decode_query()

      assert q["scope"] == "one-scope two-scope"
    end
  end

  describe "generate_state/0" do
    test "returns a hex string of random characters" do
      state = OAuth.generate_state()

      assert state
      assert String.length(state) == 32
    end

    test "saves a flag the state in redis" do
      state = OAuth.generate_state()
      {:ok, redis} = ExistExtras.Redis.redis_connection()

      assert Redix.command!(redis, ~w(GET google:state:#{state})) == "1"
    end

    test "expires the state in 5 seconds" do
      state = OAuth.generate_state()
      {:ok, redis} = ExistExtras.Redis.redis_connection()

      assert Redix.command!(redis, ~w(TTL google:state:#{state})) > 280
    end
  end

  describe "state_valid?/1" do
    test "returns false if the state is unknown" do
      assert OAuth.state_valid?("bad-state") == false
    end

    test "returns true if the state is known" do
      assert OAuth.state_valid?(OAuth.generate_state()) == true
    end
  end

  describe "save_access_token/3" do
    test "persists the given access token assigned to the given user_id" do
      OAuth.save_access_token "some-id", "some-token", 15

      assert Redix.command!(
        ExistExtras.Redis.redis_connection!(),
        ~w(GET google:access_tokens:some-id)
      ) == "some-token"
    end

    test "expires the token after the given expires_in" do
      OAuth.save_access_token "some-id", "some-token", 15

      ttl = Redix.command!(
        ExistExtras.Redis.redis_connection!(),
        ~w(TTL google:access_tokens:some-id)
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
        ~w(GET google:refresh_tokens:some-id)
      ) == "some-token"
    end

    test "adds the user_id to the User IDs set" do
      OAuth.save_refresh_token "some-id", "some-token"

      assert Redix.command!(
        ExistExtras.Redis.redis_connection!(),
        ~w(SMEMBERS google:user_ids)
      ) == ["some-id"]
    end
  end
end

defmodule ExistExtras.Google.OauthTestSync do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    ExVCR.Config.cassette_library_dir "fixtures/vcr_cassettes"
    :ok
  end

  alias ExistExtras.Google.OAuth

  describe "authorize/1" do
    test "uses the given `code` to authorize the user with Google" do
      use_cassette "google_authorize_code" do
        user_id = OAuth.authorize("a-noice-code")
        assert user_id == "105080967267504390361"
      end
    end

    test "persists the given refresh and access tokens, and the user_id" do
      use_cassette "google_authorize_code" do
        redis = ExistExtras.Redis.redis_connection!()

        OAuth.authorize("a-noice-code")

        [user_ids, at, ttl, rt] = Redix.pipeline!(redis, [
          ~w(SMEMBERS google:user_ids),
          ~w(GET google:access_tokens:105080967267504390361),
          ~w(TTL google:access_tokens:105080967267504390361),
          ~w(GET google:refresh_tokens:105080967267504390361)
        ])

        assert Enum.any?(user_ids, fn val -> val == "105080967267504390361" end)
        assert at == "an-access-token"
        assert ttl == 3600
        assert rt == "a-refresh-token"
      end
    end
  end

  describe "authorization_endpoint/0" do
    test "fetches google's Discovery doc and returns the authorization_endpoint" do
      Redix.command! ExistExtras.Redis.redis_connection!(), ~w(DEL cache:google:discovery_doc)

      use_cassette "google_discovery_file" do
        assert OAuth.authorization_endpoint() == "https://accounts.google.com/o/oauth2/v2/auth"
      end
    end
  end

  describe "token_endpoint/0" do
    test "fetches google's Discovery doc and returns the token_endpoint" do
      Redix.command! ExistExtras.Redis.redis_connection!(), ~w(DEL cache:google:discovery_doc)

      use_cassette "google_discovery_file" do
        assert OAuth.token_endpoint() == "https://www.googleapis.com/oauth2/v4/token"
      end
    end
  end
end
