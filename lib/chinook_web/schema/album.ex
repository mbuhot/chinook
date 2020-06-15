defmodule ChinookWeb.Schema.Album do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Relay
  alias ChinookWeb.Schema.Album.Resolvers
  alias ChinookWeb.Schema.Artist
  alias ChinookWeb.Schema.Track

  node object(:album, id_fetcher: &Resolvers.id/2) do
    field :title, non_null(:string)

    connection field :tracks, node_type: :track do
      resolve(fn pagination_args, %{source: album} ->
        Relay.resolve_connection_batch(
          {Track.Resolvers, :tracks_for_album_ids, pagination_args},
          cursor_field: :track_id,
          batch_key: album.album_id
        )
      end)
    end

    field :artist, :artist do
      resolve(fn album, _args, _resolution ->
        Relay.resolve_batch(
          {Artist.Resolvers, :artists_by_ids},
          batch_key: album.artist_id
        )
      end)
    end
  end

  defmodule Resolvers do
    alias Chinook.Album
    alias Chinook.Artist
    alias Chinook.CursorQuery
    alias Chinook.Repo
    import Ecto.Query

    @spec id(Chinook.Album.t(), map) :: integer()
    def id(%Album{album_id: id}, _resolution), do: id

    @spec by_id(integer, map) :: Album.t()
    def by_id(id, _resolution) do
      Repo.get(Album, id)
    end

    @spec albums_by_ids([], [album_id]) :: %{album_id => Album.t()}
          when album_id: integer
    def albums_by_ids([], album_ids) do
      Album
      |> where([a], a.album_id in ^Enum.uniq(album_ids))
      |> Repo.all()
      |> Map.new(&{&1.album_id, &1})
    end

    @spec albums_for_artist_ids(PagingOptions.t(), [artist_id]) :: %{artist_id => Album.t()}
          when artist_id: integer
    def albums_for_artist_ids(args, ids) do
      Artist
      |> CursorQuery.cursor_assoc(:albums, args)
      |> where([a], a.artist_id in ^ids)
      |> Repo.all()
      |> Enum.group_by(& &1.artist_id)
    end
  end
end
