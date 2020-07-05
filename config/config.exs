use Mix.Config

# Configure Mix tasks and generators
config :chinook_repo,
  ecto_repos: [ChinookRepo]

# Configures the endpoint
config :chinook_host, ChinookHost.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "JbKAvKMZmfbEOrkrmOgXm0AlBMghU2BqcShu5x3/Bpr1dtJIJI26hGm8i4D10We3",
  render_errors: [view: ChinookHost.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Chinook.PubSub,
  live_view: [signing_salt: "Fh4tYzPZiayxyhjD"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config.
import_config "#{Mix.env()}.exs"
