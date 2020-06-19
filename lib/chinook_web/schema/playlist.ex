defmodule ChinookWeb.Schema.Playlist do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Relay

  @desc "Playlist sort order"
  enum :playlist_sort_order do
    value :id, as: :playlist_id
    value :name, as: :name
  end

  node object(:playlist, id_fetcher: &Relay.id/2) do
    field :name, non_null(:string)

    connection field :tracks, node_type: :track do
      arg :by, :track_sort_order, default_value: :track_id

      resolve fn playlist, args, %{context: %{loader: loader}} ->
        Relay.resolve_connection_dataloader(
          loader,
          Chinook.Track.Loader,
          Chinook.Track,
          args,
          playlist_id: playlist.playlist_id
        )
      end
    end
  end
end
