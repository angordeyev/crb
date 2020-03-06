# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :nadia,
  proxy: "http://173.249.50.151:3128", # or {:socks5, 'proxy_host', proxy_port}
  proxy_auth: {"proxyclient", "2M2Q7pKhYNmGQW2HyLzRhooBZE4a"},
  ssl: [versions: [:'tlsv1.2']]

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

#config :crbbots, start: :true
# config :tzdata, :autoupdate, :disabled

# config :logger, backends: [ {LoggerFileBackend, :error_log}, :console],
#    level: :debug

# config :logger, backends: [ {LoggerFileBackend, :error_log}, :console],
#    level: :debug

# config :logger, :error_log,
#   path: "error.log",
#   level: :info

# config :nadia,
#   token: "removed"






# You can configure your application as:
#
#     config :crybomix, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:crb, :key)
#
# You can also configure a 3rd-party app:
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
