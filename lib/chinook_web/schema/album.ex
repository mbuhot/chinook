defmodule ChinookWeb.Schema.Album do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias ChinookWeb.Relay
  alias ChinookWeb.Schema.Album.Resolvers
  alias ChinookWeb.Schema.Track

  node object(:album, id_fetcher: &Resolvers.id/2) do
    field :title, non_null(:string)

    connection field :tracks, node_type: :track do
      resolve(fn pagination_args, %{source: album} ->
        Relay.resolve_connection_batch(
          {Track.Resolvers, :tracks_for_album_ids, pagination_args},
          cursor_field: :track_id,
          batch_key: album.album_id
        )
      end)
    end

    field :artist, :artist, resolve: dataloader(Chinook)
  end

  defmodule Resolvers do
    import Ecto.Query
    import Chinook.QueryHelpers, only: [paginate: 3, batch_by: 4]

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
      from(Album, as: :album)
      |> paginate(:album, args)
      |> batch_by(:album, :artist_id, artist_ids)
      |> select([_artist, album], album)
      |> Repo.all()
      |> Enum.group_by(& &1.artist_id)
    end
  end
end
