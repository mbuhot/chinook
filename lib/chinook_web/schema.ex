defmodule ChinookWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias ChinookWeb.Schema.Album
  alias ChinookWeb.Schema.Artist
  alias ChinookWeb.Schema.Genre
  alias ChinookWeb.Schema.Track
  alias ChinookWeb.Schema.Playlist
  alias ChinookWeb.Relay

  import_types(Album)
  import_types(Artist)
  import_types(Genre)
  import_types(Track)
  import_types(Playlist)

  node interface do
    resolve_type(fn
      %Chinook.Artist{}, _ -> :artist
      %Chinook.Album{}, _ -> :album
      %Chinook.Track{}, _ -> :track
      %Chinook.Genre{}, _ -> :genre
      %Chinook.Playlist{}, _ -> :playlist
      _, _ -> nil
    end)
  end

  connection(node_type: :artist)
  connection(node_type: :album)
  connection(node_type: :track)
  connection(node_type: :genre)
  connection(node_type: :playlist)

  query do
    node field do
      resolve(fn
        %{type: :artist, id: id}, resolution ->
          {:ok, Artist.Resolvers.by_id(id, resolution)}

        %{type: :album, id: id}, resolution ->
          {:ok, Album.Resolvers.by_id(id, resolution)}

        %{type: :track, id: id}, resolution ->
          {:ok, Track.Resolvers.by_id(id, resolution)}

        %{type: :genre, id: id}, resolution ->
          {:ok, Genre.Resolvers.by_id(id, resolution)}

        %{type: :playlist, id: id}, resolution ->
          {:ok, Playlist.Resolvers.by_id(id, resolution)}
      end)
    end

    @desc "Paginate artists"
    connection field :artists, node_type: :artist do
      resolve(fn
        pagination_args, _ ->
          Relay.resolve_connection(
            {Artist.Resolvers, :resolve_connection, pagination_args},
            cursor_field: :artist_id
          )
      end)
    end

    @desc "Paginate genres"
    connection field :genres, node_type: :genre do
      resolve(fn
        pagination_args, _ ->
          Relay.resolve_connection(
            {Genre.Resolvers, :resolve_connection, pagination_args},
            cursor_field: :genre_id
          )
      end)
    end

    @desc "Paginate playlists"
    connection field :playlists, node_type: :playlist do
      resolve(fn
        pagination_args, _ ->
          Relay.resolve_connection(
            {Playlist.Resolvers, :resolve_connection, pagination_args},
            cursor_field: :playlist_id
          )
      end)
    end
  end
end
