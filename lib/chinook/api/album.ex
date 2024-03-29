defmodule Chinook.API.Schema.Album do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  # import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Chinook.API.Relay

  @desc "Album sort order"
  enum :album_sort_order do
    value(:id, as: :album_id)
    value(:title, as: :title)
    value(:artist_name, as: :artist_name)
  end

  @desc "Album filter"
  input_object :album_filter do
    field :title, :string_filter
  end

  node object(:album, id_fetcher: &Relay.id/2) do
    field :title, non_null(:string)
    field :artist, :artist, resolve: Relay.node_dataloader(Chinook.Loader)

    connection field :tracks, node_type: :track do
      arg(:by, :track_sort_order, default_value: :track_id)
      arg(:filter, :track_filter, default_value: %{})
      resolve(Relay.connection_dataloader(Chinook.Loader))
    end
  end

  def resolve_node(id, resolution) do
    Relay.node_dataloader(Chinook.Loader, Chinook.Album, id, resolution)
  end

  def resolve_connection do
    Relay.connection_from_query(&Chinook.Album.Loader.query/1)
  end
end
