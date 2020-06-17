defmodule ChinookWeb.Schema.Playlist do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Schema.Playlist.Resolvers
  alias ChinookWeb.Schema.Track
  alias ChinookWeb.Relay

  @desc "Playlist sort order"
  enum :playlist_sort_order do
    value :id, as: :playlist_id
    value :name, as: :name
  end

  node object(:playlist, id_fetcher: &Resolvers.id/2) do
    field(:name, non_null(:string))

    connection field :tracks, node_type: :track do
      arg :by, :track_sort_order

      resolve(fn args, %{source: playlist} ->
        args = Map.put_new(args, :by, :track_id)

        Relay.resolve_connection_batch(
          {Track.Resolvers, :tracks_for_playlist_ids, args},
          batch_key: playlist.playlist_id
        )
      end)
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    import Chinook.QueryHelpers, only: [paginate: 3]

    alias Chinook.Playlist
    alias Chinook.PagingOptions
    alias Chinook.Repo

    @spec id(Chinook.Playlist.t(), map) :: integer
    def id(%Playlist{playlist_id: id}, _resolution), do: id

    @spec by_id(integer, map) :: Chinook.Genre.t()
    def by_id(id, _resolution) do
      Repo.get(Playlist, id)
    end

    @spec resolve_connection(PagingOptions.t()) :: [Genre.t()]
    def resolve_connection(pagination_args) do
      from(Playlist, as: :playlist)
      |> paginate(:playlist, pagination_args)
      |> Repo.all()
    end
  end
end
