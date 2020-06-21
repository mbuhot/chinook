defmodule Chinook.Artist do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Album

  @type t :: %__MODULE__{}

  @primary_key {:artist_id, :integer, source: :ArtistId}

  schema "Artist" do
    field(:name, :string, source: :Name)
    has_many(:albums, Album, foreign_key: :artist_id)
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers
    alias Chinook.Repo

    @spec new() :: Dataloader.Ecto.t()
    def new() do
      Dataloader.Ecto.new(
        Repo,
        query: fn Artist, args -> query(args) end
      )
    end

    @spec by_id(integer) :: Chinook.Artist.t()
    def by_id(id) do
      Repo.get(Artist, id)
    end

    @spec page(args :: PagingOptions.t()) :: [Artist.t()]
    def page(args) do
      args
      |> query()
      |> Repo.all()
    end

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :artist_id)

      from(Artist, as: :artist)
      |> paginate(:artist, args)
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
