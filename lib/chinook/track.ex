defmodule Chinook.Track do
  use Ecto.Schema

  alias __MODULE__
  alias Chinook.Album
  alias Chinook.Genre
  alias Chinook.MediaType

  @type t :: %__MODULE__{}

  @primary_key {:track_id, :integer, source: :TrackId}
  schema "Track" do
    field :name, :string, source: :Name
    field :composer, :string, source: :Composer
    field :milliseconds, :integer, source: :Milliseconds
    field :bytes, :integer, source: :Bytes
    field :unit_price, :decimal, source: :UnitPrice
    field :row_count, :integer, virtual: true

    belongs_to :media_type, MediaType,
      foreign_key: :media_type_id,
      references: :media_type_id,
      source: :MediaTypeId

    belongs_to :genre, Genre, foreign_key: :genre_id, references: :genre_id, source: :GenreId
    belongs_to :album, Album, foreign_key: :album_id, references: :album_id, source: :AlbumId
    has_one :artist, through: [:album, :artist]
    has_many :invoice_lines, Chinook.Invoice.Line, foreign_key: :track_id, references: :track_id
    has_many :purchasers, through: [:invoice_lines, :invoice, :customer]
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :track_id)

      Track
      |> from(as: :track)
      |> select_fields(Track, :track, args[:fields])
      |> do_paginate(args)
      |> filter(args[:filter])
    end

    defp do_paginate(query, %{by: :artist_name} = args) do
      query
      |> join(:inner, [track: t], assoc(t, :artist), as: :artist)
      |> paginate(Track, :track, :artist, %{args | by: :name})
    end

    defp do_paginate(query, args) do
      query
      |> paginate(Track, :track, args)
    end

    def filter(queryable, nil), do: queryable

    def filter(queryable, filters) do
      Enum.reduce(filters, queryable, fn
        {:name, name_filter}, queryable ->
          filter_string(queryable, :name, name_filter)

        {:composer, composer_filter}, queryable ->
          filter_string(queryable, :composer, composer_filter)

        {:duration, duration_filter}, queryable ->
          filter_number(queryable, :milliseconds, duration_filter)

        {:bytes, bytes_filter}, queryable ->
          filter_number(queryable, :bytes, bytes_filter)

        {:unit_price, price_filter}, queryable ->
          filter_number(queryable, :unit_price, price_filter)
      end)
    end

    # This code no longer needed - Dataloader.Ecto can take care of it
    # # Handle playlist batches specially due to the join table
    # defp run_batch(Track, query, :playlist_id, playlist_ids, repo_opts) do
    #   groups =
    #     from(track in query,
    #       join: playlist_track in PlaylistTrack,
    #       as: :playlist_track,
    #       on: track.track_id == playlist_track.track_id
    #     )
    #     |> batch_by(:playlist_track, :playlist_id, playlist_ids)
    #     |> select([playlist, track], {playlist.id, track})
    #     |> Repo.all(repo_opts)
    #     |> Enum.group_by(fn {playlist_id, _} -> playlist_id end, fn {_, track} -> track end)

    #   for playlist_id <- playlist_ids do
    #     Map.get(groups, playlist_id, [])
    #   end
    # end

    # # album/genre batches can use the default run_batch
    # defp run_batch(Track, query, key_field, inputs, repo_opts) do
    #   Dataloader.Ecto.run_batch(Repo, Track, query, key_field, inputs, repo_opts)
    # end
  end
end
