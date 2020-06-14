defmodule ChinookWeb.Schema.Artist do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Schema.Album
  alias ChinookWeb.Schema.Artist.Resolvers
  alias ChinookWeb.SchemaUtil

  node object :artist, id_fetcher: &Resolvers.id/2 do
    field(:name, non_null(:string))

    connection field :albums, node_type: :album do
      resolve fn
        pagination_args, %{source: artist} ->
          pagination_args = SchemaUtil.decode_cursor(pagination_args, :album_id)
          SchemaUtil.connection_batch(Album.Resolvers, :albums_for_artist_ids, pagination_args, artist.artist_id)
      end
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    alias Chinook.Artist
    alias Chinook.Repo
    alias Chinook.QueryUtils

    def id(%Artist{artist_id: id}, _resolution), do: id

    def by_id(id, _resolution) do
      Repo.get(Artist, id)
    end

    def cursor(pagination_args) do
      Artist
      |> QueryUtils.cursor_by(pagination_args)
      |> Repo.all()
      |> Enum.sort_by(&Map.get(&1, pagination_args.cursor_field))
    end

    def artists_by_ids(_args, artist_ids) do
      Artist
      |> where([a], a.artist_id in ^Enum.uniq(artist_ids))
      |> Repo.all()
      |> Map.new(&{&1.artist_id, &1})
    end
  end
end
