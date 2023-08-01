defmodule Chinook.API.Schema.Artist do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Chinook.API.Relay
  alias Chinook.API.Scope

  @desc "Artist sort order"
  enum :artist_sort_order do
    value(:id, as: :artist_id)
    value(:name, as: :name)
  end

  @desc "Artist filter"
  input_object :artist_filter do
    field :name, :string_filter
  end

  node object(:artist, id_fetcher: &Relay.id/2) do
    field :name, non_null(:string)

    connection field(:albums, node_type: :album) do
      arg(:by, :album_sort_order, default_value: :album_id)
      arg(:filter, :album_filter, default_value: %{})
      resolve(Relay.connection_dataloader(Chinook.Loader))
    end

    connection field(:tracks, node_type: :track) do
      arg(:by, :track_sort_order, default_value: :track_id)
      arg(:filter, :track_filter, default_value: %{})
      resolve(Relay.connection_dataloader(Chinook.Loader))
    end

    connection field(:fans, node_type: :customer) do
      arg(:by, :customer_sort_order, default_value: :customer_id)
      arg(:filter, :customer_filter, default_value: %{})

      middleware(Scope, read: :customer)
      resolve(Relay.connection_dataloader(Chinook.Loader))
    end
  end

  def resolve_node(id, resolution) do
    Relay.node_dataloader(Chinook.Loader, Chinook.Artist, id, resolution)
  end

  def resolve_connection do
    Relay.connection_from_query(&Chinook.Artist.Loader.query/1)
  end
end
