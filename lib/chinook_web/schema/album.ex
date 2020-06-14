defmodule ChinookWeb.Schema.Album do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern


  alias ChinookWeb.Schema.Album.Resolvers
  alias ChinookWeb.Schema.Artist
  alias ChinookWeb.Schema.Track
  alias ChinookWeb.SchemaUtil

  node object :album, id_fetcher: &Resolvers.id/2 do
    field :title, non_null(:string)

    field :tracks, list_of(:track) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :integer)
      arg(:after, :integer)

      resolve(fn album, args, _resolution ->
        SchemaUtil.batch(Track.Resolvers, :tracks_for_album_ids, args, album.album_id)
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
      |> QueryUtils.cursor_assoc(:albums, :album_id, args)
      |> where([a], a.artist_id in ^ids)
      |> Repo.all()
      |> Enum.group_by(& &1.artist_id)
    end
  end
end
