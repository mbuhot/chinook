defmodule ChinookWeb.Schema.Genre do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias ChinookWeb.Schema.Track
  alias ChinookWeb.Schema.Genre.Resolvers
  alias ChinookWeb.Relay

  node object(:genre, id_fetcher: &Resolvers.id/2) do
    field(:name, non_null(:string))

    connection field :tracks, node_type: :track do
      resolve(fn pagination_args, %{source: genre} ->
        Relay.resolve_connection_batch(
          {Track.Resolvers, :tracks_for_genre_ids, pagination_args},
          cursor_field: :track_id,
          batch_key: genre.genre_id
        )
      end)
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    alias Chinook.CursorQuery
    alias Chinook.Genre
    alias Chinook.PagingOptions
    alias Chinook.Repo

    @spec id(Chinook.Genre.t(), map) :: integer
    def id(%Genre{genre_id: id}, _resolution), do: id

    @spec by_id(integer, map) :: Chinook.Genre.t()
    def by_id(id, _resolution) do
      Repo.get(id, Genre)
    end

    @spec resolve_cursor(PagingOptions.t()) :: [Genre.t()]
    def resolve_cursor(pagination_args) do
      Genre
      |> CursorQuery.cursor_by(pagination_args)
      |> Repo.all()
    end

    @spec genres_by_ids([], [genre_id]) :: %{genre_id => Genre.t()}
          when genre_id: integer
    def genres_by_ids(_args, genre_ids) do
      Genre
      |> where([g], g.genre_id in ^Enum.uniq(genre_ids))
      |> Repo.all()
      |> Map.new(&{&1.genre_id, &1})
    end
  end
end
