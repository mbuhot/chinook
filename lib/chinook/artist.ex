defmodule Chinook.Artist do
  use Ecto.Schema
  alias Chinook.Album

  @type t :: %__MODULE__{}

  @primary_key {:artist_id, :integer, source: :ArtistId}

  schema "Artist" do
    field :name, :string, source: :Name
    has_many :albums, Album, foreign_key: :artist_id
  end
end
