defmodule Chinook.MediaType do
  use Ecto.Schema

  @primary_key {:media_type_id, :integer, source: :MediaTypeId}

  schema "MediaType" do
    field :name, :string, source: :Name
  end
end
