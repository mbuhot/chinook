defmodule Chinook.Repo.Migrations.Initdb do
  use Ecto.Migration

  def change do
    "priv/repo/chinook_ddl.sql"
    |> File.read!()
    |> String.split(";")
    |> Enum.each(fn stmt ->
      execute(stmt)
    end)
  end
end
