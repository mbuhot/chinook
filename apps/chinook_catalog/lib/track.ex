defmodule Chinook.Catalog.Track do
  use Ecto.Schema

  alias __MODULE__
  alias Chinook.Catalog.Album
  alias Chinook.Catalog.Genre
  alias Chinook.Catalog.MediaType

  @type t :: %__MODULE__{}

  @primary_key {:track_id, :integer, source: :TrackId}
  schema "Track" do
    field :name, :string, source: :Name
    field :composer, :string, source: :Composer
    field :milliseconds, :integer, source: :Milliseconds
    field :bytes, :integer, source: :Bytes
    field :unit_price, :decimal, source: :UnitPrice
    field :row_count, :integer, virtual: true

    belongs_to :media_type, MediaType,
      foreign_key: :media_type_id,
      references: :media_type_id,
      source: :MediaTypeId

    belongs_to :genre, Genre, foreign_key: :genre_id, references: :genre_id, source: :GenreId
    belongs_to :album, Album, foreign_key: :album_id, references: :album_id, source: :AlbumId
    # has_many :invoice_lines, Chinook.Invoice.Line, foreign_key: :track_id, references: :track_id
    # has_many :purchasers, through: [:invoice_lines, :invoice, :customer]
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.Util.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :track_id)

      Track
      |> from(as: :track)
      |> paginate(Track, :track, args)
      |> filter(args[:filter])
    end

    def filter(queryable, nil), do: queryable

    def filter(queryable, filters) do
      Enum.reduce(filters, queryable, fn
        {:name, name_filter}, queryable ->
          filter_string(queryable, :name, name_filter)

        {:composer, composer_filter}, queryable ->
          filter_string(queryable, :composer, composer_filter)

        {:duration, duration_filter}, queryable ->
          filter_number(queryable, :milliseconds, duration_filter)

        {:bytes, bytes_filter}, queryable ->
          filter_number(queryable, :bytes, bytes_filter)

        {:unit_price, price_filter}, queryable ->
          filter_number(queryable, :unit_price, price_filter)
      end)
    end
  end

  defmodule Schema do
    use Absinthe.Schema.Notation
    use Absinthe.Relay.Schema.Notation, :modern

    import Absinthe.Resolution.Helpers, only: [dataloader: 1]
    alias Chinook.Util.Relay

    @desc "Track sort order"
    enum :track_sort_order do
      value :id, as: :track_id
      value :name, as: :name
      value :duration, as: :milliseconds
    end

    @desc "Track filter"
    input_object :track_filter do
      field :name, :string_filter
      field :composer, :string_filter
      field :duration, :int_filter
      field :bytes, :int_filter
      field :unit_price, :decimal_filter
    end

    node object(:track, id_fetcher: &Relay.id/2) do
      field :name, non_null(:string)

      field :duration, non_null(:integer) do
        resolve fn _args, %{source: track} -> {:ok, Map.get(track, :milliseconds)} end
      end

      field :composer, :string
      field :bytes, non_null(:integer)
      field :unit_price, non_null(:decimal)

      field :genre, :genre, resolve: dataloader(Chinook.Catalog.Loader)
      field :album, :album, resolve: dataloader(Chinook.Catalog.Loader)

      # connection field :purchasers, node_type: :customer do
      #   arg :by, :customer_sort_order, default_value: :customer_id
      #   arg :filter, :customer_filter, default_value: %{}

      #   middleware Scope, read: :customer
      #   resolve Relay.connection_dataloader(Chinook.Sales.Loader)
      # end
    end
  end
end
