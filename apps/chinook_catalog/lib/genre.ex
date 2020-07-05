defmodule Chinook.Catalog.Genre do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Catalog.Track

  @type t :: %__MODULE__{}

  @primary_key {:genre_id, :integer, source: :GenreId}

  schema "Genre" do
    field(:name, :string, source: :Name)
    field :row_count, :integer, virtual: true

    has_many(:tracks, Track, foreign_key: :genre_id)
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.Util.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :genre_id)

      Genre
      |> from(as: :genre)
      |> paginate(Genre, :genre, args)
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

    @desc "Genre sort order"
    enum :genre_sort_order do
      value :id, as: :genre_id
      value :name, as: :name
    end

    @desc "Genre filter"
    input_object :genre_filter do
      field :name, :string_filter
    end

    node object(:genre, id_fetcher: &Relay.id/2) do
      field :name, non_null(:string)

      connection field :tracks, node_type: :track do
        arg :by, :track_sort_order, default_value: :track_id
        arg :filter, :track_filter, default_value: %{}

        resolve Relay.connection_dataloader(Chinook.Catalog.Loader)
      end
    end
  end
end
