defmodule ChinookWeb.Schema.Artist do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Schema.Album
  alias ChinookWeb.Schema.Artist.Resolvers
  alias ChinookWeb.Relay

  @desc "Artist sort order"
  enum :artist_sort_order do
    value :id, as: :artist_id
    value :name, as: :name
  end

  node object(:artist, id_fetcher: &Resolvers.id/2) do
    field(:name, non_null(:string))

    connection field :albums, node_type: :album do
      arg :by, :album_sort_order

      resolve(fn args, %{source: artist} ->
        args = Map.put_new(args, :by, :album_id)

        Relay.resolve_connection_batch(
          {Album.Resolvers, :albums_for_artist_ids, args},
          batch_key: artist.artist_id
        )
      end)
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    import Chinook.QueryHelpers, only: [paginate: 3]
    alias Chinook.Artist
    alias Chinook.PagingOptions
    alias Chinook.Repo

    @spec id(Chinook.Artist.t(), any) :: integer
    def id(%Artist{artist_id: id}, _resolution), do: id

    @spec by_id(integer, map) :: Chinook.Artist.t()
    def by_id(id, _resolution) do
      Repo.get(Artist, id)
    end

    @spec resolve_connection(args :: PagingOptions.t()) :: any
    def resolve_connection(pagination_args) do
      from(Artist, as: :artist)
      |> paginate(:artist, pagination_args)
      |> Repo.all()
    end
  end
end
