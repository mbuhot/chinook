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

    @spec new() :: Dataloader.Ecto.t()
    def new() do
      Dataloader.Ecto.new(
        Chinook.Repo,
        query: fn Track, args -> query(args) end,
        run_batch: &run_batch/5
      )
    end

    @spec by_id(integer) :: Track.t()
    def by_id(id) do
      Repo.get(Track, id)
    end

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :track_id)

      from(Track, as: :track)
      |> paginate(:track, args)
    end

    # Handle playlist batches specially due to the join table
    defp run_batch(Track, query, :playlist_id, playlist_ids, repo_opts) do
      groups =
        from(track in query,
        join: playlist_track in PlaylistTrack,
        as: :playlist_track,
        on: track.track_id == playlist_track.track_id
      )
      |> batch_by(:playlist_track, :playlist_id, playlist_ids)
      |> select([playlist, track], {playlist.id, track})
      |> Repo.all(repo_opts)
      |> Enum.group_by(fn {playlist_id, _} -> playlist_id end, fn {_, track} -> track end)

      for playlist_id <- playlist_ids do
        Map.get(groups, playlist_id, [])
      end
    end

    # album/genre batches can use the default run_batch
    defp run_batch(Track, query, key_field, inputs, repo_opts) do
      Dataloader.Ecto.run_batch(Repo, Track, query, key_field, inputs, repo_opts)
    end
  end
end
