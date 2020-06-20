defmodule Chinook.PlaylistTrack do
  use Ecto.Schema
  alias Chinook.Track
  alias Chinook.Playlist

  @type t :: %__MODULE__{}

  @primary_key false
  schema "PlaylistTrack" do
    belongs_to :track, Track, foreign_key: :track_id, references: :track_id, source: :TrackId

    belongs_to :playlist, Playlist,
      foreign_key: :playlist_id,
      references: :playlist_id,
      source: :PlaylistId
  end
end

defmodule Chinook.Playlist do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Track
  alias Chinook.PlaylistTrack

  @type t :: %__MODULE__{}

  @primary_key {:playlist_id, :integer, source: :PlaylistId}

  schema "Playlist" do
    field :name, :string, source: :Name

    many_to_many :tracks, Track,
      join_through: PlaylistTrack,
      join_keys: [playlist_id: :playlist_id, track_id: :track_id]
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers

    alias Chinook.Repo

    @spec new() :: Dataloader.Ecto.t()
    def new() do
      Dataloader.Ecto.new(
        Repo,
        query: fn Playlist, args -> query(args) end
      )
    end

    @spec by_id(integer) :: Playlist.t()
    def by_id(id) do
      Repo.get(Playlist, id)
    end

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :playlist_id)

      from(Playlist, as: :playlist)
      |> paginate(:playlist, args)
    end

    @spec page(args :: PagingOptions.t()) :: [Playlist.t()]
    def page(args) do
      args
      |> query()
      |> Repo.all()
    end
  end
end
