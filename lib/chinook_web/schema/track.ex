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

  node object(:track, id_fetcher: &Relay.id/2) do
    field(:name, non_null(:string))
    field :genre, :genre, resolve: dataloader(Chinook.Genre.Loader)
    field :album, :album, resolve: dataloader(Chinook.Album.Loader)
  end
end
