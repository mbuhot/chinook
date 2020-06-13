defmodule ChinookWeb.Schema.Album do
  use Absinthe.Schema.Notation
  alias Chinook.Result
  alias ChinookWeb.Schema.Track

  object :album do
    field :id, :id
    field :title, non_null(:string)

    field :tracks, list_of(:track) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :integer)
      arg(:after, :integer)

      resolve(fn album, args, _resolution ->
        batch(
          {Track.Resolvers, :tracks_for_album_ids, args},
          album.id,
          &(&1 |> Map.get(album.id) |> Result.ok())
        )
      end)
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    alias Chinook.Artist
    alias Chinook.QueryUtils
    alias Chinook.Repo

    def albums_for_artist_ids(args, ids) do
      Artist
      |> QueryUtils.cursor_assoc(:albums, :album_id, args)
      |> where([a], a.artist_id in ^ids)
      |> select([a], %{
        id: a.album_id,
        artist_id: a.artist_id,
        title: a.title
      })
      |> Repo.all()
      |> Enum.group_by(& &1.artist_id)
    end
  end
end
