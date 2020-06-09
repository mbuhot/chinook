# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :chinook,
  ecto_repos: [Chinook.Repo]

# Configures the endpoint
config :chinook, ChinookWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "P+BM8Z0wL02F2sLYS+wFyt/1/ZJr4LFtguUzm0Z8DxdurxOtFKFTqW0HyfdcyuH9",
  render_errors: [view: ChinookWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Chinook.PubSub,
  live_view: [signing_salt: "SbOH1xuS"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
