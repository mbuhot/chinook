defmodule ChinookWeb.Schema.Genre do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Relay

  @desc "Genre sort order"
  enum :genre_sort_order do
    value :id, as: :genre_id
    value :name, as: :name
  end

  node object(:genre, id_fetcher: &Relay.id/2) do
    field :name, non_null(:string)

    connection field :tracks, node_type: :track do
      arg :by, :track_sort_order, default_value: :track_id

      resolve fn genre, args, %{context: %{loader: loader}} ->
        Relay.resolve_connection_dataloader(
          loader,
          Chinook.Track.Loader,
          Chinook.Track,
          args,
          genre_id: genre.genre_id
        )
      end
    end
  end
end
