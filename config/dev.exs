use Mix.Config

config :maru, ExistExtras.Api,
  http: [port: 8880]

config :exist_extras, ExistExtras.Google.OAuth,
  redirect_uri: System.get_env("BASE_DEV_URL") <> "/google/oauth"

config :exist_extras, ExistExtras.Exist.OAuth,
  redirect_uri: System.get_env("BASE_DEV_URL") <> "/exist/oauth"

config :logger,
  backends: [:console],
  compile_time_purge_level: :debug
