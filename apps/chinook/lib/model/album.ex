defmodule Chinook.Album do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Artist
  alias Chinook.Track

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
    import Chinook.QueryHelpers

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
end
