defmodule ExistExtras.Google.OAuth do
  @moduledoc """
  Functions for handling the OAuth flow with the Google API. The state and
  tokens are stored in a Redis DB.
  """

  require Logger

  @discovery_doc_uri Keyword.fetch!(
    Application.get_env(:exist_extras, __MODULE__), :discovery_doc_uri
  )
  @client_id Keyword.fetch!(Application.get_env(:exist_extras, __MODULE__), :client_id)
  @client_secret Keyword.fetch!(Application.get_env(:exist_extras, __MODULE__), :client_secret)
  @redirect_uri Keyword.fetch!(Application.get_env(:exist_extras, __MODULE__), :redirect_uri)

  @doc """
  Authorizes the given `code` with Google. If successful, returns the user's ID.
  Otherwise, returns `nil`.
  """
  def authorize(code) do
    payload = [
      {"code", code},
      {"client_id", @client_id},
      {"client_secret", @client_secret},
      {"redirect_uri", @redirect_uri},
      {"grant_type", "authorization_code"}
    ]

    response = HTTPoison.post(
      token_endpoint(),
      {:form, payload},
      [{"Content-Type", "application/x-www-form-urlencoded"}]
    )

    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: json_body}} ->
        body = Poison.decode! json_body
        id_token = Joken.token(body["id_token"]) |> Joken.peek()

        Logger.debug("[Google] Got token claims #{inspect id_token}")
        Logger.debug("[Google] Got response body #{inspect body}")

        save_refresh_token id_token["sub"], body["refresh_token"]
        save_access_token(id_token["sub"], body["access_token"], body["expires_in"])

        id_token["sub"]
      _ -> nil
    end
  end

  @doc """
  Builds the URL for OAuth authorization with the given scopes. Always prompts,
  and provides offline access.
  """
  def build_authorize_url(scopes) do
    query = %{
      client_id: @client_id,
      redirect_uri: @redirect_uri,
      scope: Enum.join(scopes, " "),
      state: generate_state(),
      response_type: "code",
      access_type: "offline",
      prompt: "consent"
    }

    "#{authorization_endpoint()}?#{URI.encode_query(query)}"
  end

  @doc """
  Generates a random `state` string for OAuth and persists it in redis for a
  while (5min) so it can be validated.
  """
  def generate_state do
    state = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    {:ok, redis} = ExistExtras.Redis.redis_connection()

    Redix.pipeline! redis, [
      ~w(INCR google:state:#{state}),
      ~w(EXPIRE google:state:#{state} 300)
    ]

    state
  end

  @doc """
  Validates a `state` string, returns true if it has been generated recently.
  TODO: invalidate state
  """
  def state_valid?(state) do
    Logger.debug "[Google] Validating state: '#{state}'"

    {:ok, redis} = ExistExtras.Redis.redis_connection()
    Redix.command!(redis, ~w(GET google:state:#{state})) == "1"
  end

  @doc """
  Persists an access token for a `user_id`, set to expire when it is no longer
  valid.
  """
  def save_access_token(user_id, token, expires_in) do
    Logger.debug "[Google] Saving access token: '#{user_id}' - '#{token}' - '#{expires_in}'"

    {:ok, redis} = ExistExtras.Redis.redis_connection()
    Redix.pipeline! redis, [
      ~w(SET google:access_tokens:#{user_id} #{token}),
      ~w(EXPIRE google:access_tokens:#{user_id} #{expires_in})
    ]
  end

  @doc """
  Persists a refresh token for a `user_id`. Also adds the ID to the ID set, so
  we can know which users have authenticated before.
  """
  def save_refresh_token(user_id, token) do
    Logger.debug "[Google] Saving refresh token: '#{user_id}' - '#{token}'"

    {:ok, redis} = ExistExtras.Redis.redis_connection()
    Redix.pipeline! redis, [
      ~w(SADD google:user_ids #{user_id}),
      ~w(SET google:refresh_tokens:#{user_id} #{token})
    ]
  end

  @doc """
  Grabs and returns google's endpoint for initiating OAuth authorization.
  """
  def authorization_endpoint, do: discovery_doc()["authorization_endpoint"]

  @doc """
  Grabs and returns google's endpoint for OAuth token generation
  """
  def token_endpoint, do: discovery_doc()["token_endpoint"]

  defp discovery_doc do
    doc = Redix.command!(
      ExistExtras.Redis.redis_connection!(),
      ~w(GET cache:google:discovery_doc)
    ) || fetch_discovery_doc()

    Poison.decode! doc
  end

  # https://developers.google.com/identity/protocols/OpenIDConnect#discovery
  defp fetch_discovery_doc do
    {:ok, %HTTPoison.Response{status_code: 200, body: doc}} = HTTPoison.get @discovery_doc_uri
    redis = ExistExtras.Redis.redis_connection!()

    Redix.pipeline! redis, [
      ["SET" | ["cache:google:discovery_doc" | [doc | []]]],
      ~w(EXPIRE cache:google:discovery_doc 300)
    ]

    doc
  end
end
