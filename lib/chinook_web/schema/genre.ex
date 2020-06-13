defmodule ChinookWeb.Schema.Genre do
  use Absinthe.Schema.Notation
  alias ChinookWeb.Schema.Track

  object :genre do
    field(:id, :id)
    field(:name, non_null(:string))

    field :tracks, list_of(:track) do
      arg(:first, :integer)
      arg(:last, :integer)
      arg(:before, :integer)
      arg(:after, :integer)

      resolve(fn genre, args, _resolution ->
        Absinthe.Resolution.Helpers.batch(
          {Track.Resolvers, :tracks_for_genre_ids, args},
          genre.id,
          &{:ok, Map.get(&1, genre.id)}
        )
      end)
    end
  end

  defmodule Resolvers do
    import Ecto.Query
    alias Chinook.Genre
    alias Chinook.QueryUtils
    alias Chinook.Repo
    alias Chinook.Result

    def list_genres(_parent, args, _resolution) do
      Genre
      |> QueryUtils.cursor_by(:genre_id, args)
      |> select([g], %{id: g.genre_id, name: g.name})
      |> Repo.all()
      |> Result.ok()
    end

    def genres_by_ids(_args, genre_ids) do
      Genre
      |> where([g], g.genre_id in ^Enum.uniq(genre_ids))
      |> select([g], %{id: g.genre_id, name: g.name})
      |> Repo.all()
      |> Map.new(&{&1.id, &1})
    end
  end
end
