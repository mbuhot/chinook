defmodule ChinookWeb.Schema.Artist do
  use Absinthe.Schema.Notation
  alias ChinookWeb.Resolvers

  object :artist do
    field :id, :id
    field :name, non_null(:string)

    field :albums, list_of(:album) do
      resolve(&Resolvers.list_albums_for_artist/3)
    end
  end
end
