defmodule Chinook.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChinookWeb.Telemetry,
      Chinook.Repo,
      {Phoenix.PubSub, name: Chinook.PubSub},
      ChinookWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Chinook.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ChinookWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
