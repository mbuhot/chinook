defmodule ChinookHost.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ChinookHost.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Chinook.PubSub},
      # Start the Endpoint (http/https)
      ChinookHost.Endpoint
      # Start a worker by calling: ChinookHost.Worker.start_link(arg)
      # {ChinookHost.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChinookHost.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ChinookHost.Endpoint.config_change(changed, removed)
    :ok
  end
end
