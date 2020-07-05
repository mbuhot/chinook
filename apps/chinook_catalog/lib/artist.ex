defmodule Chinook.Catalog.Artist do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Catalog.Album

  @type t :: %__MODULE__{}

  @primary_key {:artist_id, :integer, source: :ArtistId}

  schema "Artist" do
    field(:name, :string, source: :Name)
    field :row_count, :integer, virtual: true

    has_many(:albums, Album, foreign_key: :artist_id)
    has_many(:tracks, through: [:albums, :tracks])
    # has_many(:fans, through: [:tracks, :purchasers])
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.Util.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :artist_id)

      Artist
      |> from(as: :artist)
      |> paginate(Artist, :artist, args)
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

    @desc "Artist sort order"
    enum :artist_sort_order do
      value :id, as: :artist_id
      value :name, as: :name
    end

    @desc "Artist filter"
    input_object :artist_filter do
      field :name, :string_filter
    end

    node object(:artist, id_fetcher: &Relay.id/2) do
      field :name, non_null(:string)

      connection field(:albums, node_type: :album) do
        arg :by, :album_sort_order, default_value: :album_id
        arg :filter, :album_filter, default_value: %{}
        resolve Relay.connection_dataloader(Chinook.Catalog.Loader)
      end

      connection field(:tracks, node_type: :track) do
        arg :by, :track_sort_order, default_value: :track_id
        arg :filter, :track_filter, default_value: %{}
        resolve Relay.connection_dataloader(Chinook.Catalog.Loader)
      end

      # connection field(:fans, node_type: :customer) do
      #   arg :by, :customer_sort_order, default_value: :customer_id
      #   arg :filter, :customer_filter, default_value: %{}

      #   middleware Scope, read: :customer
      #   resolve Relay.connection_dataloader(Chinook.Loader)
      # end
    end
  end
end
