# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

# Configure Mix tasks and generators
config :chinook,
  ecto_repos: [Chinook.Repo]

config :chinook_web,
  ecto_repos: [Chinook.Repo],
  generators: [context_app: :chinook]

# Configures the endpoint
config :chinook_web, ChinookWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JbKAvKMZmfbEOrkrmOgXm0AlBMghU2BqcShu5x3/Bpr1dtJIJI26hGm8i4D10We3",
  render_errors: [view: ChinookWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Chinook.PubSub,
  live_view: [signing_salt: "Fh4tYzPZiayxyhjD"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
