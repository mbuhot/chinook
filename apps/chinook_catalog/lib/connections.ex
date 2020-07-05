defmodule Chinook.Catalog.Connections do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias Chinook.Util.Relay

  connection(node_type: :album)
  connection(node_type: :artist)
  connection(node_type: :genre)
  connection(node_type: :playlist)
  connection(node_type: :track)

  object :catalog_connections do
    @desc "Paginate artists"
    connection field :artists, node_type: :artist do
      arg :by, :artist_sort_order, default_value: :artist_id
      arg :filter, :artist_filter, default_value: %{}

      resolve Relay.connection_from_query(&Chinook.Catalog.Artist.Loader.query/1)
    end

    @desc "Paginate genres"
    connection field :genres, node_type: :genre do
      arg :by, :genre_sort_order, default_value: :genre_id
      arg :filter, :genre_filter, default_value: %{}

      resolve Relay.connection_from_query(&Chinook.Catalog.Genre.Loader.query/1)
    end

    @desc "Paginate playlists"
    connection field :playlists, node_type: :playlist do
      arg :by, :playlist_sort_order, default_value: :playlist_id
      arg :filter, :playlist_filter, default_value: %{}

      resolve Relay.connection_from_query(&Chinook.Catalog.Playlist.Loader.query/1)
    end
  end
end
