defmodule ChinookWeb.Schema.Artist do
  use Absinthe.Schema.Notation
  alias ChinookWeb.Schema.Album
  alias ChinookWeb.SchemaUtil

  object :artist do
    field(:id, :id)
    field(:name, non_null(:string))

    field :albums, list_of(:album) do
      arg(:first, :integer)
      arg(:after, :integer)
      arg(:last, :integer)
      arg(:before, :integer)

      resolve(fn artist, args, _resolution ->
        SchemaUtil.batch(Album.Resolvers, :albums_for_artist_ids, args, artist.id)
      end)
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    alias Chinook.Artist
    alias Chinook.Repo
    alias Chinook.Result
    alias Chinook.QueryUtils

    def list_artists(_parent, args, _resolution) do
      Artist
      |> QueryUtils.cursor_by(:artist_id, args)
      |> select_fields()
      |> Repo.all()
      |> Result.ok()
    end

    def artists_by_ids(_args, artist_ids) do
      Artist
      |> where([a], a.artist_id in ^Enum.uniq(artist_ids))
      |> select_fields()
      |> Repo.all()
      |> Map.new(&{&1.id, &1})
    end

    defp select_fields(query) do
      query
      |> select([a], %{id: a.artist_id, name: a.name})
    end
  end
end
