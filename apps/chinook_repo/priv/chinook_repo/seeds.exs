# Script for populating the database. You can run it as:
#
#     mix run priv/chinook_repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ChinookRepo.insert!(%Chinook.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias ChinookRepo, as: Repo

"priv/chinook_repo/chinook_genres_artists_albums.sql"
|> File.read!()
|> String.split(~r/;\n/)
|> Enum.each(fn stmt ->
  {:ok, _} = Ecto.Adapters.SQL.query(Repo, stmt)
end)

"priv/chinook_repo/chinook_songs.sql"
|> File.read!()
|> String.split(~r/;\n/)
|> Enum.each(fn stmt ->
  {:ok, _} = Ecto.Adapters.SQL.query(Repo, stmt)
end)
