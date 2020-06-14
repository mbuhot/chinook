defmodule ChinookWeb.Schema.Album do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern


  alias ChinookWeb.Schema.Album.Resolvers
  alias ChinookWeb.Schema.Artist
  alias ChinookWeb.Schema.Track
  alias ChinookWeb.SchemaUtil

  node object :album, id_fetcher: &Resolvers.id/2 do
    field :title, non_null(:string)

    connection field :tracks, node_type: :track do
      resolve fn
        pagination_args, %{source: album} ->
          pagination_args = pagination_args |> SchemaUtil.decode_cursor(:track_id)
          SchemaUtil.connection_batch(Track.Resolvers, :tracks_for_album_ids, pagination_args, album.album_id)
      end
    end

    field :artist, :artist do
      resolve fn album, _args, _resolution ->
        SchemaUtil.batch(Artist.Resolvers, :artists_by_ids, album.artist_id)
      end
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    alias Chinook.Artist
    alias Chinook.Album
    alias Chinook.QueryUtils
    alias Chinook.Repo

    def id(%Album{album_id: id}, _resolution), do: id

    def by_id(id, _resolution) do
      Repo.get(Album, id)
    end

    def albums_by_ids(_args, album_ids) do
      Album
      |> where([a], a.album_id in ^Enum.uniq(album_ids))
      |> Repo.all()
      |> Map.new(&{&1.album_id, &1})
    end

    def albums_for_artist_ids(args, ids) do
      Artist
      |> QueryUtils.cursor_assoc(:albums, args)
      |> where([a], a.artist_id in ^ids)
      |> Repo.all()
      |> Enum.group_by(& &1.artist_id)
    end
  end
end
