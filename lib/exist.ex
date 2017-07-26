defmodule ExistExtras.Exist do
  require Logger

  @doc """
  Returns whether the user with the given `user_id` is authorized with Exist.
  """
  def authorized?(user_id) do
    !!Redix.command!(
      ExistExtras.Redis.redis_connection!(),
      ~w(GET exist:access_tokens:#{user_id})
    )
  end

  @doc """
  Grabs our owned attributes from Exist.
  """
  def acquired_attributes(user_id) do
    response = HTTPoison.get!(
      "https://exist.io/api/1/attributes/owned/",
      authorized_headers(user_id)
    )

    Logger.debug("[Exist] Got owned attributes: #{inspect response}")

    Poison.decode!(response.body)
  end

  @doc """
  Acquires ownership of the required attributes in Exist.
  """
  def acquire_attribute_ownership(user_id) do
    attributes = [
      %{name: "energy", active: true},
      %{name: "carbohydrates", active: true},
      %{name: "fat", active: true},
      %{name: "fibre", active: true},
      %{name: "protein", active: true},
      %{name: "sugar", active: true},
      %{name: "sodium", active: true},
      %{name: "cholesterol", active: true}
    ]

    response = HTTPoison.post!(
      "https://exist.io/api/1/attributes/acquire/",
      Poison.encode!(attributes),
      authorized_headers(user_id, [{"Content-Type", "application/json"}])
    )

    Logger.debug("[Exist] Saved attribute ownership: #{inspect response}")

    :ok
  end

  @doc """
  Sends nutrition data to Elixir on behalf of the user for `user_id`. The
  attributes will be saved to the given `date`
  """
  def save_nutrition(user_id, date, attributes) do
    body = Enum.map(attributes, fn {name, value} ->
      %{name: name, value: value, date: date}
    end)

    response = HTTPoison.post!(
      "https://exist.io/api/1/attributes/update/",
      Poison.encode!(body),
      authorized_headers(user_id, [{"Content-Type", "application/json"}])
    )

    Logger.debug("[Exist] Saved nutrition: #{inspect attributes} - #{inspect response}")

    :ok
  end

  defp authorized_headers(user_id, extra_headers \\ []) do
    access_token = Redix.command!(
      ExistExtras.Redis.redis_connection!(),
      ~w(GET exist:access_tokens:#{user_id})
    )

    [
      {"Authorization", "Bearer #{access_token}"},
      {"Accept", "application/json"}
      | extra_headers
    ]
  end
end
