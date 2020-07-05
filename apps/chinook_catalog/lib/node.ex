defmodule Chinook.Catalog.Node do
  alias Chinook.Catalog.Album
  alias Chinook.Catalog.Artist
  alias Chinook.Catalog.Genre
  alias Chinook.Catalog.Loader
  alias Chinook.Catalog.Playlist
  alias Chinook.Catalog.Track
  alias Chinook.Util.Relay

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
