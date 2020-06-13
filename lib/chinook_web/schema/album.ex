defmodule ChinookWeb.Schema.Album do
  use Absinthe.Schema.Notation
  alias ChinookWeb.Schema.Artist
  alias ChinookWeb.Schema.Track
  alias ChinookWeb.SchemaUtil

  object :album do
    field :id, :id
    field :title, non_null(:string)

    field :tracks, list_of(:track) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :integer)
      arg(:after, :integer)

      resolve(fn album, args, _resolution ->
        SchemaUtil.batch(Track.Resolvers, :tracks_for_album_ids, args, album.id)
      end)
    end

    field :artist, :artist do
      resolve(fn album, args, _resolution ->
        SchemaUtil.batch(Artist.Resolvers, :artists_by_ids, args, album.artist_id)
      end)
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    alias Chinook.Artist
    alias Chinook.Album
    alias Chinook.QueryUtils
    alias Chinook.Repo

    def albums_by_ids(_args, album_ids) do
      Album
      |> where([a], a.album_id in ^Enum.uniq(album_ids))
      |> select_fields()
      |> Repo.all()
      |> Map.new(&{&1.id, &1})
    end

    def albums_for_artist_ids(args, ids) do
      Artist
      |> QueryUtils.cursor_assoc(:albums, :album_id, args)
      |> where([a], a.artist_id in ^ids)
      |> select_fields()
      |> Repo.all()
      |> Enum.group_by(& &1.artist_id)
    end

    defp select_fields(query) do
      query
      |> select([a], %{
        id: a.album_id,
        artist_id: a.artist_id,
        title: a.title
      })
    end
  end
end
