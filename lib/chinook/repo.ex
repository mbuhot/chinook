defmodule Chinook.Repo do
  use Ecto.Repo,
    otp_app: :chinook,
    adapter: Ecto.Adapters.Postgres
end
