defmodule Chinook.Genre do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Track

  @type t :: %__MODULE__{}

  @primary_key {:genre_id, :integer, source: :GenreId}

  schema "Genre" do
    field(:name, :string, source: :Name)
    field :row_count, :integer, virtual: true

    has_many(:tracks, Track, foreign_key: :genre_id)
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :genre_id)

      Genre
      |> from(as: :genre)
      |> select_fields(Genre, :genre, args[:fields])
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
end
