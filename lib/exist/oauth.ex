defmodule ExistExtras.Exist.OAuth do
  @moduledoc """
  Functions for dealing with Exist's OAuth flow. Tokens are persisted in a Redis
  DB.
  """

  require Logger

  @doc """
  Uses the given code to authorize the current User with Exist. Saves the
  received Access & Refresh Tokens to Redis.
  """
  def authorize(user_id, code) do
    payload = [
      {"code", code},
      {"client_id", client_id()},
      {"client_secret", client_secret()},
      {"redirect_uri", redirect_uri()},
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

        Logger.debug("[Exist] Got response body #{inspect body}")

        save_refresh_token user_id, body["refresh_token"]
        save_access_token user_id, body["access_token"], body["expires_in"]

        :ok
      _ -> :error
    end
  end

  @doc """
  Builds the URL for initiating the OAuth sequence in Exist. Requests read+write
  scopes.
  """
  def build_authorize_url do
    query = %{
      client_id: client_id(),
      redirect_uri: redirect_uri(),
      scope: "read+write",
      response_type: "code"
    }

    "#{authorization_endpoint()}?#{URI.encode_query(query)}"
  end

  @doc """
  Persists an access token for a `user_id`, set to expire when it is no longer
  valid.
  """
  def save_access_token(user_id, token, expires_in) do
    Logger.debug "[Exist] Saving access token: '#{user_id}' - '#{token}' - '#{expires_in}'"

    {:ok, redis} = ExistExtras.Redis.redis_connection
    Redix.pipeline! redis, [
      ~w(SET exist:access_tokens:#{user_id} #{token}),
      ~w(EXPIRE exist:access_tokens:#{user_id} #{expires_in})
    ]
  end

  @doc """
  Persists a refresh token for a `user_id`. Also adds the ID to the ID set, so
  we can know which users have authenticated before.
  """
  def save_refresh_token(user_id, token) do
    Logger.debug "[Exist] Saving refresh token: '#{user_id}' - '#{token}'"

    {:ok, redis} = ExistExtras.Redis.redis_connection
    Redix.pipeline! redis, [
      ~w(SADD exist:user_ids #{user_id}),
      ~w(SET exist:refresh_tokens:#{user_id} #{token})
    ]
  end

  @doc """
  Grabs and returns exist's endpoint for initiating OAuth authorization.
  """
  def authorization_endpoint do
    ExistExtras.fetch_config!(:exist_extras, __MODULE__, :authorization_endpoint)
  end

  @doc """
  Grabs and returns exist's endpoint for OAuth token generation
  """
  def token_endpoint do
    ExistExtras.fetch_config!(:exist_extras, __MODULE__, :token_endpoint)
  end

  defp client_id do
    ExistExtras.fetch_config!(:exist_extras, __MODULE__, :client_id)
  end

  defp client_secret do
    ExistExtras.fetch_config!(:exist_extras, __MODULE__, :client_secret)
  end

  defp redirect_uri do
    ExistExtras.fetch_config!(:exist_extras, __MODULE__, :redirect_uri)
  end
end
