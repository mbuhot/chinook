defmodule Chinook.Catalog.Album do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Catalog.Artist
  alias Chinook.Catalog.Track

  @type t :: %__MODULE__{}

  @primary_key {:album_id, :integer, source: :AlbumId}

  schema "Album" do
    field :title, :string, source: :Title
    field :row_count, :integer, virtual: true

    belongs_to :artist, Artist, foreign_key: :artist_id, references: :artist_id, source: :ArtistId
    has_many :tracks, Track, foreign_key: :album_id
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.Util.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :album_id)

      Album
      |> from(as: :album)
      |> paginate(Album, :album, args)
      |> filter(args[:filter])
    end

    def filter(queryable, nil), do: queryable

    def filter(queryable, filters) do
      Enum.reduce(filters, queryable, fn
        {:title, title_filter}, queryable -> filter_string(queryable, :title, title_filter)
      end)
    end
  end

  defmodule Schema do
    use Absinthe.Schema.Notation
    use Absinthe.Relay.Schema.Notation, :modern

    import Absinthe.Resolution.Helpers, only: [dataloader: 1]

    alias Chinook.Util.Relay

    @desc "Album sort order"
    enum :album_sort_order do
      value :id, as: :album_id
      value :title, as: :title
    end

    @desc "Album filter"
    input_object :album_filter do
      field :title, :string_filter
    end

    node object(:album, id_fetcher: &Relay.id/2) do
      field :title, non_null(:string)
      field :artist, :artist, resolve: dataloader(Chinook.Catalog.Loader)

      connection field :tracks, node_type: :track do
        arg :by, :track_sort_order, default_value: :track_id
        arg :filter, :track_filter, default_value: %{}
        resolve Relay.connection_dataloader(Chinook.Catalog.Loader)
      end
    end
  end
end
