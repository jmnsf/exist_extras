defmodule ExistExtras.Exist do
  @doc """
  Returns whether the user with the given `user_id` is authorized with Exist.
  """
  def authorized?(user_id) do
    !!Redix.command!(
      ExistExtras.Redis.redis_connection!(),
      ~w(GET exist:access_tokens:#{user_id})
    )
  end
end
