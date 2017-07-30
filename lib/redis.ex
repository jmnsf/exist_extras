defmodule ExistExtras.Redis do
  require Logger

  def redis_connection do
    Redix.start_link endpoint()
  end

  def redis_connection! do
    {:ok, redis} = redis_connection()
    redis
  end

  defp endpoint do
    ExistExtras.fetch_config!(:exist_extras, ExistExtras.Redis, :endpoint)
  end
end
