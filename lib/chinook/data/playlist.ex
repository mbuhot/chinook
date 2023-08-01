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
    field :row_count, :integer, virtual: true

    many_to_many :tracks, Track,
      join_through: PlaylistTrack,
      join_keys: [playlist_id: :playlist_id, track_id: :track_id]
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :playlist_id)

      Playlist
      |> from(as: :playlist)
      |> select_fields(Playlist, :playlist, args[:fields])
      |> paginate(Playlist, :playlist, args)
      |> filter(args[:filter])
    end

    def filter(queryable, nil), do: queryable

    def filter(queryable, filters) do
      Enum.reduce(filters, queryable, fn
        {:name, name_filter}, queryable -> filter_string(queryable, :name, name_filter)
      end)
    end
  end
end
