defmodule Chinook.AlbumTest do
  use Chinook.DataCase, async: true
  import Ecto.Query

  alias Chinook.Repo
  alias Chinook.Artist
  alias Chinook.Album
  alias Chinook.Track
  @album_ids [50, 60, 70, 80, 90, 100, 110, 120, 130, 141, 147]

  describe "Preload with joins" do
    test "Preload tracks with join and subquery condition" do
      query =
        from album in Album,
          left_join: track in assoc(album, :tracks),
          where:
            track.track_id in fragment(
              """
                SELECT "TrackId"
                FROM "Track"
                WHERE "AlbumId" = ?
                ORDER BY "Milliseconds" DESC
                LIMIT 3
              """,
              album.album_id
            ),
          preload: [tracks: {track, :genre}],
          where: album.album_id in ^@album_ids,
          select: album

      [a1, a2 | _rest] = Repo.all(query)
      assert length(a1.tracks) == 3
      assert length(a2.tracks) == 3
    end

    test "Preload tracks with lateral join" do
      query =
        from album in Album,
          left_lateral_join:
            top_tracks in fragment(
              """
              (
                SELECT "TrackId" as track_id
                FROM "Track"
                WHERE "AlbumId" = ?
                ORDER BY "Milliseconds" DESC
                LIMIT 3
              )
              """,
              album.album_id
            ),
          left_join: track in Track,
          on: track.track_id == top_tracks.track_id,
          preload: [tracks: {track, :genre}],
          where: album.album_id in ^@album_ids,
          select: album

      [a1, a2 | _rest] = Repo.all(query)
      assert length(a1.tracks) == 3
      assert length(a2.tracks) == 3
    end
  end

  def default_opts(opts, default_opts) do
    Enum.reduce(opts, Map.new(default_opts), fn {k, v}, acc -> %{acc | k => v} end)
  end

  def partition_limit(queryable, opts) when is_atom(queryable),
    do: partition_limit(from(queryable), opts)

  def partition_limit(queryable, opts) do
    opts = opts |> default_opts(partition_by: nil, order_by: nil, limit: nil)
    %{from: %{source: {_, schema}}} = queryable
    [primary_key] = schema.__schema__(:primary_key)

    ranking_query =
      from r in queryable,
        select: %{id: field(r, ^primary_key), rank: row_number() |> over(:w)},
        windows: [w: [partition_by: ^opts.partition_by, order_by: ^opts.order_by]]

    from row in schema,
      join: top_rows in subquery(ranking_query),
      on: field(row, ^primary_key) == top_rows.id,
      where: top_rows.rank <= ^opts.limit,
      select: row
  end

  def preload_limit(query, association, opts) do
    opts = opts |> default_opts(order_by: nil, limit: nil, repo: nil)
    %{from: %{source: {_, source_schema}}} = query

    %{queryable: related_queryable, related_key: related_key} =
      source_schema.__schema__(:association, association)

    preloader =
      case opts.repo do
        nil ->
          related_queryable
          |> partition_limit(
            partition_by: related_key,
            order_by: opts.order_by,
            limit: opts.limit
          )

        repo ->
          fn ids ->
            preload_query =
              related_queryable
              |> where([x], field(x, ^related_key) in ^ids)
              |> partition_limit(
                partition_by: related_key,
                order_by: opts.order_by,
                limit: opts.limit
              )

            repo.all(preload_query)
          end
      end

    query |> preload([{^association, ^preloader}])
  end

  defp association_details(parent_schema, association) do
    assoc_info = parent_schema.__schema__(:association, association)
    child_schema = assoc_info.queryable
    [parent_primary_key] = parent_schema.__schema__(:primary_key)
    [child_primary_key] = child_schema.__schema__(:primary_key)

    %{
      parent_schema: parent_schema,
      parent_primary_key: parent_primary_key,
      child_schema: child_schema,
      child_primary_key: child_primary_key,
      related_key: assoc_info.related_key
    }
  end

  def top_n(parent_schema, association, opts) do
    {where, opts} = Keyword.pop(opts, :where, [])
    {order_by, opts} = Keyword.pop!(opts, :order_by)
    {limit, []} = Keyword.pop!(opts, :limit)

    %{
      parent_primary_key: parent_primary_key,
      child_schema: child_schema,
      child_primary_key: child_primary_key,
      related_key: related_key
    } = association_details(parent_schema, association)

    from child in child_schema,
      join: parent in ^parent_schema, as: :parent,
      on: field(child, ^related_key) == field(parent, ^parent_primary_key),
      inner_lateral_join:
        top_children in subquery(
          from top_children in child_schema,
            where: field(top_children, ^related_key) == field(parent_as(:parent), ^parent_primary_key),
            where: ^where,
            order_by: ^order_by,
            limit: ^limit,
            select: ^[child_primary_key]
        ),
      on: field(top_children, ^child_primary_key) == field(child, ^child_primary_key),
      select: child
  end

  describe "Preload with Query" do
    @tag :focus
    test "Preload tracks with generic inner_lateral_join" do
      query =
        from artist in Artist,
        order_by: artist.artist_id,
        limit: 10,
        select: artist,
        preload: [
          albums:
            ^top_n(Artist, :albums,
              where: dynamic([a], like(a.title, "%Rock%")),
              order_by: :title,
              limit: 1
            )
        ],
        preload: [
          albums: [
            tracks:
              ^top_n(Album, :tracks,
                where: dynamic([t], t.name |> ilike("%E%")),
                order_by: :name,
                limit: 3
              )
          ]
        ]

      IO.inspect(query)

      [a1, a2 | _rest] = Repo.all(query)
      album1 = hd(a1.albums) |> IO.inspect()
      assert length(album1.tracks) == 3
      # assert length(a1.tracks) == 3
      # assert length(a2.tracks) == 3
    end

    test "Preload tracks with query using windows" do
      tracks_query =
        from track in Track,
          join:
            top_track in subquery(
              from t in Track,
                select: %{track_id: t.track_id, rank: row_number() |> over(:album)},
                windows: [album: [partition_by: :album_id, order_by: [desc: :milliseconds]]]
            ),
          on: track.track_id == top_track.track_id,
          where: top_track.rank <= 3,
          select: track,
          preload: :genre

      query =
        from album in Album,
          where: album.album_id in ^@album_ids,
          preload: [tracks: ^tracks_query],
          select: album

      [a1, a2 | _rest] = Repo.all(query)
      assert length(a1.tracks) == 3
      assert length(a2.tracks) == 3
    end

    test "Preload tracks with generic query using windows" do
      tracks_query =
        partition_limit(Track, partition_by: :album_id, order_by: [desc: :milliseconds], limit: 3)

      query =
        from album in Album,
          where: album.album_id in ^@album_ids,
          preload: [tracks: ^tracks_query],
          select: album

      [a1, a2 | _rest] = Repo.all(query)
      assert length(a1.tracks) == 3
      assert length(a2.tracks) == 3
    end

    test "Preload tracks with lateral join query" do
      album_ids = @album_ids

      tracks_query =
        from track in Track,
          join: album in assoc(track, :album),
          as: :album,
          inner_lateral_join:
            top_track in subquery(
              from Track,
                where: [album_id: parent_as(:album).album_id],
                order_by: [desc: :milliseconds],
                limit: 3,
                select: [:track_id]
            ),
          on: top_track.track_id == track.track_id

      query =
        from album in Album,
          where: album.album_id in ^album_ids,
          preload: [tracks: ^tracks_query],
          select: album

      length(Repo.all(query)) |> IO.inspect()
    end

    test "Preload tracks with generic helper" do
      query =
        Album
        |> where([album], album.album_id in ^@album_ids)
        |> preload_limit(:tracks, order_by: [desc: :milliseconds], limit: 3)
        |> select([album], album)

      [a1, a2 | _rest] = Repo.all(query)
      assert length(a1.tracks) == 3
      assert length(a2.tracks) == 3
    end

    test "Preload tracks with optimised generic helper" do
      query =
        Album
        |> where([album], album.album_id in ^@album_ids)
        |> preload_limit(:tracks, order_by: [desc: :milliseconds], limit: 3, repo: Repo)
        |> select([album], album)

      [a1, a2 | _rest] = Repo.all(query)
      assert length(a1.tracks) == 3
      assert length(a2.tracks) == 3
    end

    test "Preload multiple levels with optimised generic helper" do
      alias Chinook.Artist

      query =
        Artist
        |> where([artist], artist.artist_id in ^[100, 105])
        |> preload(
          albums:
            ^(Album |> partition_limit(partition_by: :artist_id, order_by: :title, limit: 2))
        )
        |> preload(
          albums: [
            tracks:
              ^partition_limit(Track, partition_by: :album_id, order_by: :milliseconds, limit: 2)
          ]
        )
        |> preload(albums: [tracks: :genre])
        |> select([album], album)

      [a1, a2 | _rest] = Repo.all(query)
      # assert length(a1.albums) == 2
      # assert length(a2.albums) == 2
    end
  end

  describe "Preload with function" do
    test "Preload tracks with custom function" do
      tracks_func = fn album_ids ->
        tracks_query =
          from track in Track,
            join:
              top_track in subquery(
                from t in Track,
                  select: %{track_id: t.track_id, rank: row_number() |> over(:album)},
                  windows: [album: [partition_by: :album_id, order_by: [desc: :milliseconds]]],
                  where: t.album_id in ^album_ids
              ),
            on: track.track_id == top_track.track_id,
            where: top_track.rank <= 3,
            select: track,
            preload: :genre

        Repo.all(tracks_query)
      end

      query =
        from album in Album,
          where: album.album_id in ^@album_ids,
          preload: [tracks: ^tracks_func],
          select: album

      [a1, a2 | _rest] = Repo.all(query)
      assert length(a1.tracks) == 3
      assert length(a2.tracks) == 3
    end

    test "Preload tracks with raw SQL and function" do
      tracks_func = fn limit ->
        fn ids ->
          result =
            Repo.query!(
              """
              SELECT *
              FROM (
                SELECT
                top_track.*, row_number() OVER "w" AS "rank"
                FROM "Track" AS top_track
                WINDOW "w" AS (PARTITION BY top_track."AlbumId" ORDER BY top_track."Milliseconds" DESC)
              ) as t
              WHERE (t."rank" <= $1) AND t."AlbumId" = ANY($2)
              """,
              [limit, ids]
            )

          Enum.map(result.rows, &Repo.load(Track, {result.columns, &1}))
        end
      end

      query =
        from album in Album,
          where: album.album_id in ^@album_ids,
          preload: [tracks: ^tracks_func.(3)],
          preload: [tracks: :genre],
          select: album

      [a1, a2 | _rest] = Repo.all(query)
      assert length(a1.tracks) == 3
      assert length(a2.tracks) == 3
    end

    def longest_tracks_per_album(limit: limit) do
      fn album_ids ->
        Repo.query!(
          """
          SELECT track.*
          FROM unnest($1::int[]) as album(album_id)
          LEFT JOIN LATERAL (
            SELECT *
            FROM "Track"
            WHERE "AlbumId" = album.album_id
            ORDER BY "Milliseconds" DESC
            LIMIT $2) track ON true
          """,
          [album_ids, limit]
        )
        |> case do
          %{rows: rows, columns: cols} -> Enum.map(rows, &Repo.load(Track, {cols, &1}))
        end
      end
    end

    test "Preload tracks with lateral join raw SQL and function" do
      query =
        from album in Album,
          where: album.album_id in ^@album_ids,
          preload: [tracks: ^longest_tracks_per_album(limit: 3)],
          preload: [tracks: :genre],
          select: album

      [a1, a2 | _rest] = Repo.all(query)
      assert length(a1.tracks) == 3
      assert length(a2.tracks) == 3
    end
  end
end
