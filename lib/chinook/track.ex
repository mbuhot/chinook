defmodule Chinook.Track do
  use Ecto.Schema

  alias Chinook.Album
  alias Chinook.Genre
  alias Chinook.MediaType

  @primary_key {:track_id, :integer, source: :TrackId}
  schema "Track" do
    field :name, :string, source: :Name
    field :composer, :string, source: :Composer
    field :milliseconds, :integer, source: :Milliseconds
    field :bytes, :integer, source: :Bytes
    field :unit_price, :decimal, source: :UnitPrice

    belongs_to :media_type, MediaType, foreign_key: :media_type_id, references: :media_type_id, source: :"MediaTypeId"
    belongs_to :genre, Genre, foreign_key: :genre_id, references: :genre_id, source: :"GenreId"
    belongs_to :album, Album, foreign_key: :album_id, references: :album_id, source: :"AlbumId"
  end
end
