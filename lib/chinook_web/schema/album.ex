defmodule ChinookWeb.Schema.Album do
  use Absinthe.Schema.Notation
  alias ChinookWeb.Resolvers

  object :album do
    field :id, :id
    field :title, non_null(:string)

    field :tracks, list_of(:track) do
      resolve(&Resolvers.tracks_for_album/3)
    end
  end
end
