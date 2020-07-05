defmodule Chinook.AlbumTest do
  use ChinookRepo.DataCase, async: true
  import Ecto.Query

  alias ChinookRepo, as: Repo
  alias Chinook.Catalog.Artist
  alias Chinook.Catalog.Album
  alias Chinook.Catalog.Track
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

  def partition_limit(queryable, opts) do
    {partition_by, opts} = Keyword.pop!(opts, :partition_by)
    {order_by, opts} = Keyword.pop!(opts, :order_by)
    {limit, opts} = Keyword.pop!(opts, :limit)
    {where, []} = Keyword.pop(opts, :where, [])

    %{from: %{source: {_, schema}}} = from(queryable)
    [primary_key] = schema.__schema__(:primary_key)

    ranking_query =
      from r in queryable,
        where: ^where,
        select: map(r, ^[primary_key]),
        select_merge: %{rank: row_number() |> over(:w)},
        windows: [w: [partition_by: ^partition_by, order_by: ^order_by]]

    from row in schema,
      join: top_rows in subquery(ranking_query),
      on: field(row, ^primary_key) == field(top_rows, ^primary_key),
      where: top_rows.rank <= ^limit,
      select: row
  end

  def preload_limit(query, association, opts) do
    {order_by, opts} = Keyword.pop!(opts, :order_by)
    {limit, opts} = Keyword.pop!(opts, :limit)
    {repo, []} = Keyword.pop(opts, :repo, nil)

    %{from: %{source: {_, source_schema}}} = query

    %{queryable: related_queryable, related_key: related_key} =
      source_schema.__schema__(:association, association)

    preloader =
      case repo do
        nil ->
          related_queryable
          |> partition_limit(
            partition_by: related_key,
            order_by: order_by,
            limit: limit
          )

        repo ->
          fn ids ->
            preload_query =
              related_queryable
              |> partition_limit(
                where: dynamic([x], field(x, ^related_key) in ^ids),
                partition_by: related_key,
                order_by: order_by,
                limit: limit
              )

            repo.all(preload_query)
          end
      end

    query |> preload([{^association, ^preloader}])
  end

  def top_n(schema, association, opts) do
    {where, opts} = Keyword.pop(opts, :where, [])
    {order_by, opts} = Keyword.pop!(opts, :order_by)
    {limit, []} = Keyword.pop!(opts, :limit)

    assoc_info = schema.__schema__(:association, association)
    assoc_schema = assoc_info.queryable
    [assoc_primary_key] = assoc_schema.__schema__(:primary_key)
    related_key = assoc_info.related_key

    from associated in assoc_schema,
      as: :associated,
      inner_lateral_join:
        top_associated in subquery(
          from top_associated in assoc_schema,
            where:
              field(top_associated, ^related_key) == field(parent_as(:associated), ^related_key),
            where: ^where,
            order_by: ^order_by,
            limit: ^limit,
            select: ^[assoc_primary_key]
        ),
      on: field(top_associated, ^assoc_primary_key) == field(associated, ^assoc_primary_key),
      select: associated
  end

  describe "Preload with Query" do
    test "Preload tracks with generic inner_lateral_join" do
      query =
        from artist in Artist,
          order_by: artist.artist_id,
          limit: 10,
          select: artist,
          preload: [
            albums:
              ^top_n(Artist, :albums,
                order_by: :title,
                limit: 1
              )
          ],
          preload: [
            albums: [
              tracks:
                ^top_n(Album, :tracks,
                  order_by: :name,
                  limit: 3
                )
            ]
          ]

      [a1 | _rest] = Repo.all(query)
      album1 = hd(a1.albums)
      assert length(album1.tracks) == 3
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

      assert length(Repo.all(query)) == 11
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

      [a1 | _rest] = Repo.all(query)
      assert length(a1.albums) == 1
      assert length(hd(a1.albums).tracks) == 2
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
            ORDER BY "Name" DESC
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
