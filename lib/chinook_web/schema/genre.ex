defmodule ChinookWeb.Schema.Genre do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Schema.Track
  alias ChinookWeb.Schema.Genre.Resolvers
  alias ChinookWeb.Relay

  @desc "Genre sort order"
  enum :genre_sort_order do
    value :id, as: :genre_id
    value :name, as: :name
  end

  node object(:genre, id_fetcher: &Resolvers.id/2) do
    field(:name, non_null(:string))

    connection field :tracks, node_type: :track do
      arg(:by, :track_sort_order)

      resolve(fn args, %{source: genre} ->
        args = Map.put_new(args, :by, :track_id)

        Relay.resolve_connection_batch(
          {Track.Resolvers, :tracks_for_genre_ids, args},
          batch_key: genre.genre_id
        )
      end)
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    import Chinook.QueryHelpers, only: [paginate: 3]
    alias Chinook.Genre
    alias Chinook.PagingOptions
    alias Chinook.Repo

    @spec id(Chinook.Genre.t(), map) :: integer
    def id(%Genre{genre_id: id}, _resolution), do: id

    @spec by_id(integer, map) :: Chinook.Genre.t()
    def by_id(id, _resolution) do
      Repo.get(Genre, id)
    end

    @spec resolve_connection(PagingOptions.t()) :: [Genre.t()]
    def resolve_connection(pagination_args) do
      from(Genre, as: :genre)
      |> paginate(:genre, pagination_args)
      |> Repo.all()
    end
  end
end
