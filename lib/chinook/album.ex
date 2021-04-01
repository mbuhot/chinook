defmodule Chinook.Album do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Artist
  alias Chinook.Track

  @type t :: %__MODULE__{}

  @primary_key {:album_id, :integer, source: :AlbumId}

  schema "Album" do
    field :title, :string, source: :Title
    field :row_count, :integer, virtual: true

    belongs_to :artist, Artist, foreign_key: :artist_id, references: :artist_id, source: :ArtistId
    has_many :tracks, Track, foreign_key: :album_id
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :album_id)

      Album
      |> from(as: :album)
      |> select_fields(Album, :album, args[:fields])
      |> do_paginate(args)
      |> filter(args[:filter])
    end

    defp do_paginate(query, args = %{by: :artist_name}) do
      query
      |> join(:inner, [album: a], assoc(a, :artist), as: :artist)
      |> paginate(Album, :album, :artist, %{args | by: :name})
    end

    defp do_paginate(query, args), do: paginate(query, Album, :album, args)

    def filter(queryable, nil), do: queryable

    def filter(queryable, filters) do
      Enum.reduce(filters, queryable, fn
        {:title, title_filter}, queryable -> filter_string(queryable, :title, title_filter)
      end)
    end
  end
end
