defmodule ChinookWeb.Schema.Artist do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Schema.Album
  alias ChinookWeb.Schema.Artist.Resolvers
  alias ChinookWeb.SchemaUtil

  node object :artist, id_fetcher: &Resolvers.id/2 do
    field(:name, non_null(:string))

    field :albums, list_of(:album) do
      arg(:first, :integer)
      arg(:after, :integer)
      arg(:last, :integer)
      arg(:before, :integer)

      resolve(fn artist, args, _resolution ->
        SchemaUtil.batch(Album.Resolvers, :albums_for_artist_ids, args, artist.artist_id)
      end)
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    alias Chinook.Artist
    alias Chinook.Repo
    alias Chinook.Result
    alias Chinook.QueryUtils

    def id(%Artist{artist_id: id}, _resolution), do: id

    def by_id(id, _resolution) do
      Repo.get(Artist, id)
    end

    def list_artists(_parent, args, _resolution) do
      Artist
      |> QueryUtils.cursor_by(:artist_id, args)
      |> Repo.all()
      |> Result.ok()
    end

    def artists_by_ids(_args, artist_ids) do
      Artist
      |> where([a], a.artist_id in ^Enum.uniq(artist_ids))
      |> Repo.all()
      |> Map.new(&{&1.artist_id, &1})
    end
  end
end
