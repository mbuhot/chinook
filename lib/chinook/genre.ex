defmodule Chinook.Genre do
  use Ecto.Schema
  alias Chinook.Track

  @primary_key {:genre_id, :integer, source: :GenreId}

  schema "Genre" do
    field :name, :string, source: :Name
    has_many :tracks, Track, foreign_key: :genre_id
  end
end
