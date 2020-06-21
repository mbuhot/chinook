defmodule ChinookWeb.Schema.Artist do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Relay

  @desc "Artist sort order"
  enum :artist_sort_order do
    value :id, as: :artist_id
    value :name, as: :name
  end

  @desc "Artist filter"
  input_object :artist_filter do
    field :name, :string_filter
  end

  node object(:artist, id_fetcher: &Relay.id/2) do
    field :name, non_null(:string)

    connection field(:albums, node_type: :album) do
      arg :by, :album_sort_order, default_value: :album_id
      arg :filter, :album_filter, default_value: %{}

      resolve Relay.connection_dataloader(
        Chinook.Album.Loader,
        fn artist, args, _res ->
          {Chinook.Album, args, artist_id: artist.artist_id}
        end
      )
    end
  end
end
