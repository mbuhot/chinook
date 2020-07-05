defmodule ChinookRepo.Application do
  use Application

  def start(_type, _args) do
    children = [ChinookRepo]
    opts = [strategy: :one_for_one, name: Chinook.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
