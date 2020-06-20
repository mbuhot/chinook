defmodule Chinook.Genre do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Track

  @type t :: %__MODULE__{}

  @primary_key {:genre_id, :integer, source: :GenreId}

  schema "Genre" do
    field(:name, :string, source: :Name)
    has_many(:tracks, Track, foreign_key: :genre_id)
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers

    alias Chinook.Repo

    def new() do
      Dataloader.Ecto.new(Repo, query: &query/2)
    end

    @spec by_id(integer) :: Chinook.Genre.t()
    def by_id(id) do
      Repo.get(Genre, id)
    end

    def query(Genre, args) do
      args = Map.put_new(args, :by, :genre_id)

      from(Genre, as: :genre)
      |> paginate(:genre, args)
    end

    @spec page(args :: PagingOptions.t()) :: Genre.t()
    def page(args) do
      query(Genre, args)
      |> Repo.all()
    end
  end
end
