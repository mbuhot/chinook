defmodule ChinookWeb.Schema.Genre do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation

  alias ChinookWeb.Schema.Track
  alias ChinookWeb.Schema.Genre.Resolvers
  alias ChinookWeb.SchemaUtil

  node object :genre, id_fetcher: &Resolvers.id/2 do
    field(:name, non_null(:string))

    connection field :tracks, node_type: :track do
      resolve fn pagination_args, %{source: genre} ->
        pagination_args = SchemaUtil.decode_cursor(pagination_args, :track_id)
        SchemaUtil.connection_batch(Track.Resolvers, :tracks_for_genre_ids, pagination_args, genre.genre_id)
      end
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    alias Chinook.Genre
    alias Chinook.QueryUtils
    alias Chinook.Repo
    alias Chinook.Result

    def id(%Genre{genre_id: id}, _resolution), do: id

    def by_id(id, _resolution) do
      Repo.get(id, Genre)
    end

    def cursor(pagination_args) do
      Genre
      |> QueryUtils.cursor_by(pagination_args)
      |> Repo.all()
    end

    def genres_by_ids(_args, genre_ids) do
      Genre
      |> where([g], g.genre_id in ^Enum.uniq(genre_ids))
      |> Repo.all()
      |> Map.new(&{&1.genre_id, &1})
    end
  end
end
