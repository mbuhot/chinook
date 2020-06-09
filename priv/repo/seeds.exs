# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Chinook.Repo.insert!(%Chinook.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Chinook.Repo

"priv/repo/chinook_genres_artists_albums.sql"
|> File.read!()
|> String.split(~r/;\n/)
|> Enum.each(fn stmt ->
  {:ok, _} = Ecto.Adapters.SQL.query(Repo, stmt)
end)

"priv/repo/chinook_songs.sql"
|> File.read!()
|> String.split(~r/;\n/)
|> Enum.each(fn stmt ->
  {:ok, _} = Ecto.Adapters.SQL.query(Repo, stmt)
end)
