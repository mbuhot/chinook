defmodule ChinookWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias ChinookWeb.Schema.Album
  alias ChinookWeb.Schema.Artist
  alias ChinookWeb.Schema.Genre
  alias ChinookWeb.Schema.Track

  import_types(Album)
  import_types(Artist)
  import_types(Genre)
  import_types(Track)

  node interface do
    resolve_type fn
      %Chinook.Artist{}, _ -> :artist
      %Chinook.Album{}, _ -> :album
      %Chinook.Track{}, _ -> :track
      %Chinook.Genre{}, _ -> :genre
      _, _ -> nil
    end
  end

  query do
    node field do
      resolve fn
        %{type: :artist, id: id}, resolution ->
          {:ok, Artist.Resolvers.by_id(id, resolution)}

        %{type: :album, id: id}, resolution ->
          {:ok, Album.Resolvers.by_id(id, resolution)}

        %{type: :track, id: id}, resolution ->
          {:ok, Track.Resolvers.by_id(id, resolution)}

        %{type: :genre, id: id}, resolution ->
          {:ok, Genre.Resolvers.by_id(id, resolution)}
      end
    end


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
