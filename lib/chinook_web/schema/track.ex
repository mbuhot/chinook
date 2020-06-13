defmodule ChinookWeb.Schema.Track do
  use Absinthe.Schema.Notation
  alias ChinookWeb.Schema.Artist
  alias ChinookWeb.Schema.Genre

  object :track do
    field :id, :id
    field :name, non_null(:string)

    field :genre, :genre do
      resolve(fn track, _args, _resolution ->
        batch(
          {Genre.Resolvers, :genres_by_ids},
          track.genre_id,
          &{:ok, Map.get(&1, track.genre_id)}
        )
      end)
    end

    field :artist, :artist do
      resolve(fn track, _args, _resolution ->
        batch(
          {Artist.Resolvers, :artists_by_ids},
          track.artist_ids,
          &{:ok, Map.get(&1, track.artist_id)}
        )
      end)
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    alias Chinook.Album
    alias Chinook.Genre
    alias Chinook.QueryUtils
    alias Chinook.Repo

    def tracks_for_album_ids(args, album_ids) do
      Album
      |> QueryUtils.cursor_assoc(:tracks, :track_id, args)
      |> where([track], track.album_id in ^album_ids)
      |> select_fields()
      |> Repo.all()
      |> Enum.group_by(& &1.album_id)
    end

    def tracks_for_genre_ids(args, genre_ids) do
      Genre
      |> QueryUtils.cursor_assoc(:tracks, :track_id, args)
      |> where([track], track.genre_id in ^genre_ids)
      |> select_fields()
      |> Repo.all()
      |> Enum.group_by(& &1.genre_id)
    end

    defp select_fields(query) do
      query
      |> select([track], %{
        id: track.track_id,
        album_id: track.album_id,
        genre_id: track.genre_id,
        name: track.name
      })
    end
  end
end
