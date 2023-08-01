defmodule Chinook.Artist do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Album

  @type t :: %__MODULE__{}

  @primary_key {:artist_id, :integer, source: :ArtistId}

  schema "Artist" do
    field(:name, :string, source: :Name)
    field :row_count, :integer, virtual: true

    has_many(:albums, Album, foreign_key: :artist_id)
    has_many(:tracks, through: [:albums, :tracks])
    has_many(:fans, through: [:tracks, :purchasers])
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :artist_id)

      Artist
      |> from(as: :artist)
      |> select_fields(Artist, :artist, args[:fields])
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
end
