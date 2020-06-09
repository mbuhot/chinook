defmodule Chinook.Genre do
  use Ecto.Schema

  @primary_key {:genre_id, :integer, source: :GenreId}

  schema "Genre" do
    field :name, :string, source: :Name
  end
end
