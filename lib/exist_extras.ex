defmodule ExistExtras do
  @moduledoc """
  Documentation for ExistExtras.
  """

  require Logger

  def fetch_config!(app, key) when is_atom(app) and is_atom(key) do
    fetch_config!(app, key, nil)
  end

  def fetch_config!(app, module, key) when is_atom(app) and is_atom(module) and is_atom(key) do
    value = Application.get_env(app, module)

    value = if key do
      Keyword.fetch!(value, key)
    else
      value
    end

    case value do
      {:system, env, default} -> System.get_env(env) || default
      {:system, env} -> System.get_env(env)
      nil ->
        Logger.warn("[Config] Undefined setting! #{app} - #{module} - #{key}")
        nil
      val -> val
    end
  end
end
