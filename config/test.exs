use Mix.Config

config :logger,
  compile_time_purge_level: :error

config :maru, ExistExtras.Api,
  http: [port: 8888]

config :exvcr, [
  filter_sensitive_data: [
    [pattern: "Bearer \\w+", placeholder: "Bearer ACCESS_TOKEN"]
  ]
]

config :exist_extras, ExistExtras.Redis,
  endpoint: "redis://localhost/12"

config :exist_extras, ExistExtras.Api.Cookies,
  sign_key: "1234567890987654321"

config :exist_extras, ExistExtras.Google.OAuth,
  client_id: "googleClientId",
  client_secret: "googleClientSecret",
  redirect_uri: "http://localhost/google/oauth"

config :exist_extras, ExistExtras.Exist.OAuth,
  client_id: "existClientId",
  client_secret: "existClientSecret",
  redirect_uri: "http://localhost/exist/oauth"
