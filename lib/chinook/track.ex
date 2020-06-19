defmodule Chinook.Track do
  use Ecto.Schema

  alias __MODULE__
  alias Chinook.Album
  alias Chinook.Genre
  alias Chinook.MediaType

  @type t :: %__MODULE__{}

  @primary_key {:track_id, :integer, source: :TrackId}
  schema "Track" do
    field :name, :string, source: :Name
    field :composer, :string, source: :Composer
    field :milliseconds, :integer, source: :Milliseconds
    field :bytes, :integer, source: :Bytes
    field :unit_price, :decimal, source: :UnitPrice

    belongs_to :media_type, MediaType,
      foreign_key: :media_type_id,
      references: :media_type_id,
      source: :MediaTypeId

    belongs_to :genre, Genre, foreign_key: :genre_id, references: :genre_id, source: :GenreId
    belongs_to :album, Album, foreign_key: :album_id, references: :album_id, source: :AlbumId
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers
    alias Chinook.PlaylistTrack
    alias Chinook.Repo

    def new() do
      Dataloader.Ecto.new(Chinook.Repo, query: &query/2, run_batch: &run_batch/5)
    end

    @spec by_id(integer) :: Track.t()
    def by_id(id) do
      Repo.get(Track, id)
    end

    def query(Track, args) do
      args = Map.put_new(args, :by, :track_id)

      from(Track, as: :track)
      |> paginate(:track, args)
    end

    defp run_batch(Track, query, key_field, inputs, _repo_opts) do
      groups = load_tracks_by(key_field, query, inputs)

      for value <- inputs do
        Map.get(groups, value, [])
      end
    end

    defp load_tracks_by(:playlist_id, query, playlist_ids) do
      from(track in query,
        join: playlist_track in PlaylistTrack,
        as: :playlist_track,
        on: track.track_id == playlist_track.track_id
      )
      |> batch_by(:playlist_track, :playlist_id, playlist_ids)
      |> select([playlist, track], {playlist.id, track})
      |> Repo.all()
      |> Enum.group_by(fn {playlist_id, _} -> playlist_id end, fn {_, track} -> track end)
    end

    defp load_tracks_by(key_field, query, inputs) do
      query
      |> batch_by(:track, key_field, inputs)
      |> select([_, track], track)
      |> Repo.all()
      |> Enum.group_by(&Map.get(&1, key_field))
    end
  end
end
