defmodule ChinookWeb.Resolvers do
  import Ecto.Query

  alias Chinook.Album
  alias Chinook.Artist
  alias Chinook.Track
  alias Chinook.Repo

  def list_albums(_parent, _args, _resolution) do
    query =
      from(a in Album,
        select: %{
          id: a.album_id,
          title: a.title
        }
      )

    data = Repo.all(query)
    {:ok, data}
  end

  def albums_for_artist_ids(_, ids) do
    query =
      from(a in Album,
        where: a.artist_id in ^ids,
        select: %{
          id: a.album_id,
          artist_id: a.artist_id,
          title: a.title
        }
      )

    data = Repo.all(query)
    data |> Enum.group_by(fn x -> x.artist_id end)
  end

  def list_albums_for_artist(artist, _args, _resolution) do
    Absinthe.Resolution.Helpers.batch(
      {__MODULE__, :albums_for_artist_ids},
      artist.id,
      fn batch_results ->
        {:ok, Map.get(batch_results, artist.id)}
      end
    )
  end

  def list_artists(_parent, _args, _resolution) do
    query =
      from(a in Artist,
        select: %{
          id: a.artist_id,
          name: a.name
        }
      )

    data = Repo.all(query)
    {:ok, data}
  end

  def tracks_for_album_ids(_, album_ids) do
    query =
      from t in Track,
        join: g in assoc(t, :genre),
        where: t.album_id in ^album_ids,
        select: %{
          id: t.track_id,
          album_id: t.album_id,
          name: t.name,
          genre: g.name
        }

    query
    |> Repo.all()
    |> Enum.group_by(fn x -> x.album_id end)
  end

  def tracks_for_album(album, _args, _resolution) do
    Absinthe.Resolution.Helpers.batch(
      {__MODULE__, :tracks_for_album_ids},
      album.id,
      fn batch_results ->
        {:ok, Map.get(batch_results, album.id)}
      end
    )
  end
end
