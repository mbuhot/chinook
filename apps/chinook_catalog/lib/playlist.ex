defmodule Chinook.Catalog.PlaylistTrack do
  use Ecto.Schema
  alias Chinook.Catalog.Track
  alias Chinook.Catalog.Playlist

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

defmodule Chinook.Catalog.Playlist do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Catalog.Track
  alias Chinook.Catalog.PlaylistTrack

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
    import Chinook.Util.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :playlist_id)

      Playlist
      |> from(as: :playlist)
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

  defmodule Schema do
    use Absinthe.Schema.Notation
    use Absinthe.Relay.Schema.Notation, :modern

    alias Chinook.Util.Relay

    @desc "Playlist sort order"
    enum :playlist_sort_order do
      value :id, as: :playlist_id
      value :name, as: :name
    end

    @desc "Playlist filter"
    input_object :playlist_filter do
      field :name, :string_filter
    end

    node object(:playlist, id_fetcher: &Relay.id/2) do
      field :name, non_null(:string)

      connection field :tracks, node_type: :track do
        arg :by, :track_sort_order, default_value: :track_id
        arg :filter, :track_filter, default_value: %{}
        resolve Relay.connection_dataloader(Chinook.Catalog.Loader)
      end
    end
  end
end
