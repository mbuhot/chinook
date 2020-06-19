defmodule ChinookWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias ChinookWeb.Schema.Album
  alias ChinookWeb.Schema.Artist
  alias ChinookWeb.Schema.Genre
  alias ChinookWeb.Schema.Track
  alias ChinookWeb.Schema.Playlist
  alias ChinookWeb.Relay

  def context(ctx) do
    loader = Chinook.Loader.data()
    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  import_types Album
  import_types Artist
  import_types Genre
  import_types Track
  import_types Playlist

  node interface do
    resolve_type fn
      %Chinook.Artist{}, _ -> :artist
      %Chinook.Album{}, _ -> :album
      %Chinook.Track{}, _ -> :track
      %Chinook.Genre{}, _ -> :genre
      %Chinook.Playlist{}, _ -> :playlist
      _, _ -> nil
    end
  end

  connection(node_type: :artist)
  connection(node_type: :album)
  connection(node_type: :track)
  connection(node_type: :genre)
  connection(node_type: :playlist)

  query do
    node field do
      resolve(fn
        %{type: :artist, id: id}, _resolution ->
          {:ok, Chinook.Artist.Loader.by_id(id)}

        %{type: :album, id: id}, _resolution ->
          {:ok, Chinook.Album.Loader.by_id(id)}

        %{type: :track, id: id}, _resolution ->
          {:ok, Chinook.Track.Loader.by_id(id)}

        %{type: :genre, id: id}, _resolution ->
          {:ok, Chinook.Genre.Loader.by_id(id)}

        %{type: :playlist, id: id}, _resolution ->
          {:ok, Chinook.Playlist.Loader.by_id(id)}
      end)
    end

    @desc "Paginate artists"
    connection field :artists, node_type: :artist do
      arg :by, :artist_sort_order, default_value: :artist_id

      resolve fn args, _resolution ->
        Relay.resolve_connection(Chinook.Artist.Loader, :page, args)
      end
    end

    @desc "Paginate genres"
    connection field :genres, node_type: :genre do
      arg :by, :genre_sort_order, default_value: :genre_id

      resolve fn args, _resolution ->
        Relay.resolve_connection(Chinook.Genre.Loader, :page, args)
      end
    end

    @desc "Paginate playlists"
    connection field :playlists, node_type: :playlist do
      arg :by, :playlist_sort_order, default_value: :playlist_id

      resolve fn args, _resolution ->
        Relay.resolve_connection(Chinook.Playlist.Loader, :page, args)
      end
    end
  end
end
