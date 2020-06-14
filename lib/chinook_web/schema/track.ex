defmodule ChinookWeb.Schema.Track do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Schema.Album
  alias ChinookWeb.Schema.Genre
  alias ChinookWeb.Schema.Track.Resolvers
  alias ChinookWeb.SchemaUtil

  node object :track, id_fetcher: &Resolvers.id/2 do
    field :name, non_null(:string)

    field :genre, :genre do
      resolve(fn track, _args, _resolution ->
        SchemaUtil.batch(Genre.Resolvers, :genres_by_ids, track.genre_id)
      end)
    end

    field :album, :album do
      resolve(fn track, _args, _resolution ->
        SchemaUtil.batch(Album.Resolvers, :albums_by_ids, track.album_id)
      end)
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    alias Chinook.Album
    alias Chinook.Genre
    alias Chinook.QueryUtils
    alias Chinook.Repo
    alias Chinook.Track

    def id(%Track{track_id: id}, _resolution), do: id

    def by_id(id, _resolution) do
      Repo.get(Track, id)
    end

    def tracks_for_album_ids(args, album_ids) do
      Album
      |> QueryUtils.cursor_assoc(:tracks, args)
      |> where([track], track.album_id in ^album_ids)
      |> Repo.all()
      |> Enum.group_by(& &1.album_id)
    end

    def tracks_for_genre_ids(args, genre_ids) do
      Genre
      |> QueryUtils.cursor_assoc(:tracks, args)
      |> where([track], track.genre_id in ^genre_ids)
      |> Repo.all()
      |> Enum.group_by(& &1.genre_id)
    end
  end
end
