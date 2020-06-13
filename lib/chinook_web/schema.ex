defmodule ChinookWeb.Schema do
  use Absinthe.Schema

  alias ChinookWeb.Schema.Album
  alias ChinookWeb.Schema.Artist
  alias ChinookWeb.Schema.Genre
  alias ChinookWeb.Schema.Track

  import_types(Album)
  import_types(Artist)
  import_types(Genre)
  import_types(Track)

  query do
    @desc "Get all artists"
    field :artists, list_of(:artist) do
      arg(:first, :integer)
      arg(:after, :integer)
      arg(:last, :integer)
      arg(:before, :integer)
      resolve(&Artist.Resolvers.list_artists/3)
    end

    field :genres, list_of(:genre) do
      arg(:first, :integer)
      arg(:after, :integer)
      arg(:last, :integer)
      arg(:before, :integer)
      resolve(&Genre.Resolvers.list_genres/3)
    end
  end
end
