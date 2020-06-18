defmodule ChinookWeb.Schema.Album do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias ChinookWeb.Relay
  alias ChinookWeb.Schema.Album.Resolvers
  alias ChinookWeb.Schema.Track

  @desc "Album sort order"
  enum :album_sort_order do
    value :id, as: :album_id
    value :title, as: :title
  end

  node object(:album, id_fetcher: &Resolvers.id/2) do
    field :title, non_null(:string)
    field :artist, :artist, resolve: dataloader(Chinook)

    connection field :tracks, node_type: :track do
      arg :by, :track_sort_order

      resolve(fn args, %{source: album} ->
        args = Map.put_new(args, :by, :track_id)

        Relay.resolve_connection_batch(
          {Track.Resolvers, :tracks_for_album_ids, args},
          batch_key: album.album_id
        )
      end)
    end
  end

  defmodule Resolvers do
    import Chinook.QueryHelpers

    alias Chinook.Album
    alias Chinook.Repo

    @spec id(Chinook.Album.t(), map) :: integer()
    def id(%Album{album_id: id}, _resolution), do: id

    @spec by_id(integer, map) :: Album.t()
    def by_id(id, _resolution) do
      Repo.get(Album, id)
    end

    @spec albums_for_artist_ids(PagingOptions.t(), [artist_id]) :: %{artist_id => Album.t()}
          when artist_id: integer
    def albums_for_artist_ids(args, artist_ids) do
      simple_batch_paginate(Album, args, :artist_id, artist_ids)
    end
  end
end
