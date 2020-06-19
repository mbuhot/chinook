defmodule Chinook.Album do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Artist
  alias Chinook.Track

  @type t :: %__MODULE__{}

  @primary_key {:album_id, :integer, source: :AlbumId}

  schema "Album" do
    field :title, :string, source: :Title

    belongs_to :artist, Artist, foreign_key: :artist_id, references: :artist_id, source: :ArtistId

    has_many :tracks, Track, foreign_key: :album_id
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers

    alias Chinook.Repo

    def new() do
      Dataloader.Ecto.new(Chinook.Repo, query: &query/2, run_batch: simple_batch(:album, Repo))
    end

    @spec by_id(integer) :: Album.t()
    def by_id(id) do
      Repo.get(Album, id)
    end

    def query(Album, args) do
      args = Map.put_new(args, :by, :album_id)

      from(Album, as: :album)
      |> paginate(:album, args)
    end
  end
end
