# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :exist_extras, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:exist_extras, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :logger,
  backends: [:console],
  compile_time_purge_level: :info

config :maru, ExistExtras.Api,
  http: [port: 80]

config :exist_extras, ExistExtras.Api.Cookies,
  sign_key: System.get_env("COOKIE_SIGN_KEY")

config :exist_extras, ExistExtras.Redis,
  endpoint: System.get_env("REDIS_DB") || "redis://localhost/13"

config :exist_extras, ExistExtras.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET"),
  redirect_uri: "http://exist.jmnsf.com/google/oauth",
  discovery_doc_uri: "https://accounts.google.com/.well-known/openid-configuration"

config :exist_extras, ExistExtras.Exist.OAuth,
  client_id: System.get_env("EXIST_CLIENT_ID"),
  client_secret: System.get_env("EXIST_CLIENT_SECRET"),
  redirect_uri: "http://exist.jmnsf.com/exist/oauth",
  authorization_endpoint: "https://exist.io/oauth2/authorize",
  token_endpoint: "https://exist.io/oauth2/access_token"

import_config "#{Mix.env}.exs"
