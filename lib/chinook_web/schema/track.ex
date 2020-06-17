defmodule ChinookWeb.Schema.Track do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  @desc "Track sort order"
  enum :track_sort_order do
    value :id, as: :track_id
    value :name, as: :name
    value :duration, as: :milliseconds
  end

  node object(:track, id_fetcher: &Resolvers.id/2) do
    field(:name, non_null(:string))
    field :genre, :genre, resolve: dataloader(Chinook)
    field :album, :album, resolve: dataloader(Chinook)
  end

  defmodule Resolvers do
    import Ecto.Query
    import Chinook.QueryHelpers

    alias Chinook.Track
    alias Chinook.Repo
    alias Chinook.PlaylistTrack
    alias Chinook.PagingOptions

    @spec id(Chinook.Track.t(), map) :: integer()
    def id(%Track{track_id: id}, _resolution), do: id

    @spec by_id(integer, map) :: Track.t()
    def by_id(id, _resolution) do
      Repo.get(Track, id)
    end

    @spec tracks_for_album_ids(PagingOptions.t(), [album_id]) :: %{album_id => Track.t()}
          when album_id: integer
    def tracks_for_album_ids(args, album_ids) do
      simple_batch_paginate(Track, args, :album_id, album_ids)
    end

    @spec tracks_for_genre_ids(PagingOptions.t(), [genre_id]) :: %{genre_id => Track.t()}
          when genre_id: integer
    def tracks_for_genre_ids(args, genre_ids) do
      simple_batch_paginate(Track, args, :genre_id, genre_ids)
    end

    @spec tracks_for_playlist_ids(PagingOptions.t(), [playlist_id]) :: %{playlist_id => Track.t()}
          when playlist_id: integer
    def tracks_for_playlist_ids(args, playlist_ids) do
      from(playlist_track in PlaylistTrack,
        as: :playlist_track,
        join: track in assoc(playlist_track, :track),
        as: :track,
        select: track
      )
      |> paginate(:track, args)
      |> batch_by(:playlist_track, :playlist_id, playlist_ids)
      |> select([playlist, track], %{playlist_id: playlist.id, track: track})
      |> Repo.all()
      |> Enum.group_by(& &1.playlist_id, & &1.track)
    end
  end
end
