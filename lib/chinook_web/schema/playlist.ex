defmodule ChinookWeb.Schema.Playlist do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Relay

  @desc "Playlist sort order"
  enum :playlist_sort_order do
    value :id, as: :playlist_id
    value :name, as: :name
  end

  @desc "Playlist filter"
  input_object :playlist_filter do
    field :name, :string_filter
  end

  node object(:playlist, id_fetcher: &Relay.id/2) do
    field :name, non_null(:string)

    connection field :tracks, node_type: :track do
      arg :by, :track_sort_order, default_value: :track_id
      arg :filter, :track_filter, default_value: %{}
      resolve Relay.connection_dataloader(Chinook.Track.Loader)
    end
  end
end
