defmodule ChinookWeb.Schema do
  use Absinthe.Schema
  alias ChinookWeb.Resolvers

  import_types(ChinookWeb.Schema.Artist)
  import_types(ChinookWeb.Schema.Album)
  import_types(ChinookWeb.Schema.Track)

  query do
    @desc "Get all albums"
    field :albums, list_of(:album) do
      resolve(&Resolvers.list_albums/3)
    end

    @desc "Get all artists"
    field :artists, list_of(:artist) do
      resolve(&Resolvers.list_artists/3)
    end
  end
end
