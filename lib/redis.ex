defmodule ExistExtras.Redis do
  @endpoint Keyword.fetch! Application.get_env(:exist_extras, ExistExtras.Redis), :endpoint

  def redis_connection do
    Redix.start_link @endpoint
  end

  def redis_connection! do
    {:ok, redis} = redis_connection()
    redis
  end
end
