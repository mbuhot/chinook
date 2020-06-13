defmodule ChinookWeb.Schema do
  use Absinthe.Schema
  alias ChinookWeb.Resolvers

  import_types ChinookWeb.Schema.Album

  query do
    @desc "Get all albums"
    field :albums, list_of(:album) do
      resolve &Resolvers.list_albums/3
    end
  end
end
