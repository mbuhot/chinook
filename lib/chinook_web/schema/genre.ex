defmodule ChinookWeb.Schema.Genre do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Relay

  @desc "Genre sort order"
  enum :genre_sort_order do
    value :id, as: :genre_id
    value :name, as: :name
  end

  @desc "Genre filter"
  input_object :genre_filter do
    field :name, :string_filter
  end

  node object(:genre, id_fetcher: &Relay.id/2) do
    field :name, non_null(:string)

    connection field :tracks, node_type: :track do
      arg :by, :track_sort_order, default_value: :track_id
      arg :filter, :track_filter, default_value: %{}

      resolve Relay.connection_dataloader(
        Chinook.Track.Loader,
        fn genre, args, _res ->
          {Chinook.Track, args, genre_id: genre.genre_id}
        end
      )
    end
  end
end
