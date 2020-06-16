defmodule ChinookWeb.Schema.Track do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Schema.Album
  alias ChinookWeb.Schema.Genre
  alias ChinookWeb.Schema.Track.Resolvers
  alias ChinookWeb.Relay

  node object(:track, id_fetcher: &Resolvers.id/2) do
    field :name, non_null(:string)

    field :genre, :genre do
      resolve(fn track, _args, _resolution ->
        Relay.resolve_batch({Genre.Resolvers, :genres_by_ids}, batch_key: track.genre_id)
      end)
    end

    field :album, :album do
      resolve(fn track, _args, _resolution ->
        Relay.resolve_batch({Album.Resolvers, :albums_by_ids}, batch_key: track.album_id)
      end)
    end
  end

  defmodule Resolvers do
    alias Chinook.Album
    alias Chinook.Genre
    alias Chinook.CursorQuery
    alias Chinook.Repo
    alias Chinook.Track
    alias Chinook.PagingOptions

    @spec id(Chinook.Track.t(), map) :: integer()
    def id(%Track{track_id: id}, _resolution), do: id

    @spec by_id(integer, map) :: Track.t()
    def by_id(id, _resolution) do
      Repo.get(Track, id)
    end

    @spec tracks_for_album_ids(PagingOptions.t(), [album_id]) :: %{album_id => Track.t()}
          when album_id: integer
    def tracks_for_album_ids(args, album_ids) do
      Track
      |> CursorQuery.cursor_batch(args, batch_key_field: :album_id, batch_keys: album_ids)
      |> Repo.all()
      |> Enum.group_by(& &1.album_id)
    end

    @spec tracks_for_genre_ids(PagingOptions.t(), [genre_id]) :: %{genre_id => Track.t()}
          when genre_id: integer
    def tracks_for_genre_ids(args, genre_ids) do
      Track
      |> CursorQuery.cursor_batch(args, batch_key_field: :genre_id, batch_keys: genre_ids)
      |> Repo.all()
      |> Enum.group_by(& &1.genre_id)
    end
  end
end
