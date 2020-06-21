defmodule ChinookWeb.Schema.Track do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias ChinookWeb.Relay

  @desc "Track sort order"
  enum :track_sort_order do
    value :id, as: :track_id
    value :name, as: :name
    value :duration, as: :milliseconds
  end

  @desc "Track filter"
  input_object :track_filter do
    field :name, :string_filter
    field :composer, :string_filter
    field :duration, :int_filter
    field :bytes, :int_filter
    field :unit_price, :decimal_filter
  end

  node object(:track, id_fetcher: &Relay.id/2) do
    field :name, non_null(:string)

    field :duration, non_null(:integer) do
      resolve fn _args, %{source: track} -> {:ok, Map.get(track, :milliseconds)} end
    end

    field :composer, :string
    field :bytes, non_null(:integer)
    field :unit_price, non_null(:decimal)

    field :genre, :genre, resolve: dataloader(Chinook.Genre.Loader)
    field :album, :album, resolve: dataloader(Chinook.Album.Loader)
  end
end
