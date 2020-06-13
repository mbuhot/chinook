defmodule Chinook.Album do
  use Ecto.Schema
  alias Chinook.Artist
  alias Chinook.Track

  @primary_key {:album_id, :integer, source: :AlbumId}

  schema "Album" do
    field :title, :string, source: :Title
    belongs_to :artist, Artist, foreign_key: :artist_id, references: :artist_id, source: :ArtistId
    has_many :tracks, Track, foreign_key: :album_id
  end
end
