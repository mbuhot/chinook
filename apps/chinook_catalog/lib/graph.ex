defmodule Chinook.Catalog.Graph do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias Chinook.Catalog.Album
  alias Chinook.Catalog.Artist
  alias Chinook.Catalog.Genre
  alias Chinook.Catalog.Loader
  alias Chinook.Catalog.Playlist
  alias Chinook.Catalog.Track
  alias Chinook.Util.Relay

  defmacro __using__(_opts) do
    quote do
      import_types Chinook.Catalog.Album.Schema
      import_types Chinook.Catalog.Artist.Schema
      import_types Chinook.Catalog.Genre.Schema
      import_types Chinook.Catalog.Playlist.Schema
      import_types Chinook.Catalog.Track.Schema
      import_types Chinook.Catalog.Graph
    end
  end

  connection(node_type: :album)
  connection(node_type: :artist)
  connection(node_type: :genre)
  connection(node_type: :playlist)
  connection(node_type: :track)

  object :catalog_connections do
    @desc "Paginate artists"
    connection field :artists, node_type: :artist do
      arg :by, :artist_sort_order, default_value: :artist_id
      arg :filter, :artist_filter, default_value: %{}

      resolve Relay.connection_from_query(&Artist.Loader.query/1)
    end

    @desc "Paginate genres"
    connection field :genres, node_type: :genre do
      arg :by, :genre_sort_order, default_value: :genre_id
      arg :filter, :genre_filter, default_value: %{}

      resolve Relay.connection_from_query(&Genre.Loader.query/1)
    end

    @desc "Paginate playlists"
    connection field :playlists, node_type: :playlist do
      arg :by, :playlist_sort_order, default_value: :playlist_id
      arg :filter, :playlist_filter, default_value: %{}

      resolve Relay.connection_from_query(&Playlist.Loader.query/1)
    end
  end

  def resolve_type(%Album{}, _), do: :album
  def resolve_type(%Artist{}, _), do: :artist
  def resolve_type(%Genre{}, _), do: :genre
  def resolve_type(%Playlist{}, _), do: :playlist
  def resolve_type(%Track{}, _), do: :track
  def resolve_type(_, _), do: nil

  def resolve_node(%{type: :album, id: id}, %{context: %{loader: loader}}) do
    Relay.node_dataloader(loader, Loader, Album, id)
  end

  def resolve_node(%{type: :artist, id: id}, %{context: %{loader: loader}}) do
    Relay.node_dataloader(loader, Loader, Artist, id)
  end

  def resolve_node(%{type: :genre, id: id}, %{context: %{loader: loader}}) do
    Relay.node_dataloader(loader, Loader, Genre, id)
  end

  def resolve_node(%{type: :playlist, id: id}, %{context: %{loader: loader}}) do
    Relay.node_dataloader(loader, Loader, Playlist, id)
  end

  def resolve_node(%{type: :track, id: id}, %{context: %{loader: loader}}) do
    Relay.node_dataloader(loader, Loader, Track, id)
  end
end
