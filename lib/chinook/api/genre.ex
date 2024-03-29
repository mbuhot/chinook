defmodule Chinook.API.Schema.Genre do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Chinook.API.Relay

  @desc "Genre sort order"
  enum :genre_sort_order do
    value(:id, as: :genre_id)
    value(:name, as: :name)
  end

  @desc "Genre filter"
  input_object :genre_filter do
    field :name, :string_filter
  end

  node object(:genre, id_fetcher: &Relay.id/2) do
    field :name, non_null(:string)

    connection field :tracks, node_type: :track do
      arg(:by, :track_sort_order, default_value: :track_id)
      arg(:filter, :track_filter, default_value: %{})

      resolve(Relay.connection_dataloader(Chinook.Loader))
    end
  end

  def resolve_node(id, resolution) do
    Relay.node_dataloader(Chinook.Loader, Chinook.Genre, id, resolution)
  end

  def resolve_connection do
    Relay.connection_from_query(&Chinook.Genre.Loader.query/1)
  end
end
