defmodule Chinook.Repo do
  use Ecto.Repo,
    otp_app: :chinook,
    adapter: Ecto.Adapters.Postgres

  def data() do
    Dataloader.Ecto.new(__MODULE__, query: &dataloader_query/2)
  end

  def dataloader_query(schema, _params), do: schema
end
