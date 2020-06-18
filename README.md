[![Elixir CI](https://github.com/mbuhot/chinook/workflows/Elixir%20CI/badge.svg)](https://github.com/mbuhot/chinook/actions?query=workflow%3A%22Elixir+CI%22)

# Chinook

Exploring the Chinook dataset with Elixir and Ecto.

## Problem: Select top N per category

Let's start with a problem: We want to retrieve the top 10 Artists, their first album, and the first 3 tracks for those albums.
We'd like to avoid making too many SQL queries to get the data.


## Ecto associations and preloads

Ecto has a wonderful feature for working with related tables: [associations](https://hexdocs.pm/ecto/Ecto.html#module-associations). I use it to simplify having to write out join conditions, and to fetch related data in queries.

```elixir
# associations make joins easy!
from album in Album,
  join: track in assoc(album, :tracks),
  join: genre in assoc(track, :genre),
  select: %{album.title, track.name, genre.name, track.milliseconds}
```

```elixir
# associations make fetching related data easy!
query =
  from album in Album,
    preload: [:artist, tracks: :genre],
    limit: 3

albums = Repo.all(query)
album = hd(albums)
artist = album.artist
track1 = hd(album.tracks)
genre = track1.genre
```

## Limiting Preloads

If we tell ecto to preload albums and tracks for each artist, it will fetch much more data than we require.

```elixir
query =
  from artist in Artist,
    order_by: artist.name,
    preload: [albums: :tracks],
    limit: 10

Repo.all(query)
```

Ecto allows us to customize the preload in 3 ways:

 - Using a query
 - Using a join
 - Using a function

Lets try using a query:

```elixir
top_albums =
  from a in Album,
    limit: 1

query =
  from artist in Artist,
    order_by: artist.name,
    preload: [albums: ^top_albums],
    limit: 10

iex(53)> Repo.all(query)

[debug] QUERY OK source="Artist" db=3.7ms idle=1338.9ms
SELECT A0."ArtistId", A0."Name" FROM "Artist" AS A0 ORDER BY A0."Name" LIMIT 10 []

[debug] QUERY OK source="Album" db=2.7ms idle=1342.8ms
SELECT A0."AlbumId", A0."Title", A0."ArtistId", A0."ArtistId"
FROM "Album" AS A0
WHERE (A0."ArtistId" = ANY($1))
ORDER BY A0."ArtistId"
LIMIT 1
[[43, 1, 2, 239, 257, 214, 222, 215, 202, 230]]

[
  %Chinook.Artist{
    albums: [],
    artist_id: 230,
    name: "Aaron Copland & London Symphony Orchestra"
  },
  %Chinook.Artist{
    albums: [],
    artist_id: 202,
    name: "Aaron Goldberg"
  },
  ...
  %Chinook.Artist{
    albums: [
      %Chinook.Album{
        album_id: 4,
        artist_id: 1,
        title: "Let There Be Rock"
      }
    ],
    artist_id: 1,
    name: "AC/DC"
  }
]
```

We can see from the `LIMIT 1` in the SQL that was executed, only 1 album was loaded.
Not what we wanted - we need 1 album from each artist.

This is called out in the Ecto docs:

> Note: keep in mind operations like limit and offset in the preload query will affect the whole result set and not each association. For example, the query below:

```elixir
comments_query = from c in Comment, order_by: c.popularity, limit: 5
Repo.all from p in Post, preload: [comments: ^comments_query]
```

> won't bring the top of comments per post. Rather, it will only bring the 5 top comments across all posts.

## Solution 1: Where-in subquery

We can solve this problem using joins and subqueries like so:

```elixir
query =
  from artist in Artist, as: :artist,
    join: album in assoc(artist, :albums), as: :album,
    join: track in assoc(album, :tracks),
    where: artist.artist_id in subquery(
      from a in Artist,
        order_by: a.artist_id,
        limit: 10,
        select: a.artist_id
    ),
    where: album.album_id in subquery(
      from a in Album,
        where: a.artist_id == parent_as(:artist).artist_id,
        order_by: :title,
        limit: 1,
        select: a.album_id
    ),
    where: track.track_id in subquery(
      from t in Track,
      where: t.album_id == parent_as(:album).album_id,
      order_by: :name,
      limit: 3,
      select: t.track_id
    ),
    order_by: [artist.artist_id, album.album_id, track.track_id],
    select: artist,
    preload: [albums: {album, tracks: track}]

data = Repo.all(query)
```

Note the usage of [named bindings](https://hexdocs.pm/ecto/Ecto.Query.html#module-named-bindings) `as: :album` and `parent_as(:album)` to propagate bindings from the outer query into the subquery. There's several older stackoverflow and forum posts that recommend using fragments for correllated subqueries, but it's no-longer necessary!

What's the performance like?

```
[debug] QUERY OK source="Artist" db=53.6ms queue=2.9ms idle=1719.9ms
```

Not great, let's see if we can do better than 50ms.


## Solution 2: Lateral Joins

```elixir
query =
  from(artist in Artist, as: :artist,
    join: album in assoc(artist, :albums), as: :album,
    join: track in assoc(album, :tracks),
    join: top_artist in subquery(
      from Artist,
        order_by: :artist_id,
        limit: 10,
        select: [:artist_id]
    ),
    on: artist.artist_id == top_artist.artist_id,
    inner_lateral_join: top_album in subquery(
      from Album,
      where: [artist_id: parent_as(:artist).artist_id],
      limit: 1,
      order_by: :title,
      select: [:album_id]
    ),
    on: album.album_id == top_album.album_id,

    inner_lateral_join: top_track in subquery(
      from Track,
      where: [album_id: parent_as(:album).album_id],
      limit: 3,
      order_by: :name,
      select: [:track_id]
    ),
    on: track.track_id == top_track.track_id,

    order_by: [artist.artist_id, album.album_id, track.track_id],
    select: artist,
    preload: [albums: {album, tracks: track}]
  )

data = Repo.all(query)
```

```
[debug] QUERY OK source="Artist" db=3.5ms idle=1144.0ms
```

Woah! a 10x improvement by putting the limit conditions into `inner_lateral_join`!


## Solution 3: Joins with Window Functions

Window functions are great once you wrap your head around them.
In our case, we can use the `row_number over(partition by "AlbumId" order by "TrackId")` to get the rank of each track, and use it to filter the data.


```elixir
query =
  from artist in Artist,
    join: album in assoc(artist, :albums),
    join: track in assoc(album, :tracks),

    join: top_artist in subquery(
      from Artist,
        order_by: [:artist_id],
        limit: 10,
        select: [:artist_id]
    ),
    on: artist.artist_id == top_artist.artist_id,

    join: top_album in subquery(
      from a in Album,
      windows: [artist_partition: [partition_by: :artist_id, order_by: :title]],
      select: %{album_id: a.album_id, rank: row_number() |> over(:artist_partition)}
    ),
    on: (album.album_id == top_album.album_id and top_album.rank == 1),

    join: top_track in subquery(
      from t in Track,
      windows: [album_partition: [partition_by: :album_id, order_by: :name]],
      select: %{track_id: t.track_id, rank: row_number() |> over(:album_partition)}
    ),
    on: (track.track_id == top_track.track_id and top_track.rank <= 3),

    order_by: [artist.artist_id, album.album_id, track.track_id],
    select: artist,
    preload: [albums: {album, tracks: track}]

data = Repo.all(query)
```

```
[debug] QUERY OK source="Artist" db=8.6ms idle=1384.9ms
```

Performance isn't as good as the lateral join solution, but maybe we can use windows for the next solution...


## Solution 4: Preload Queries with Window

Sometimes joins are not ideal for preloads, since the rows returned from the DB now contain columns from all the tables.
We can pull out the preload queries and let ecto fetch the associated data in a separate call.

```elixir
album_query =
  from album in Album,
    join: top_album in subquery(
      from a in Album,
      windows: [artist_partition: [partition_by: :artist_id, order_by: :title]],
      select: %{album_id: a.album_id, rank: row_number() |> over(:artist_partition)}
    ), on: (album.album_id == top_album.album_id and top_album.rank == 1),
    order_by: [:title],
    select: album

track_query =
  from track in Track,
    join: top_track in subquery(
      from t in Track,
      windows: [album_partition: [partition_by: :album_id, order_by: :name]],
      select: %{track_id: t.track_id, rank: row_number() |> over(:album_partition)}
    ), on: (track.track_id == top_track.track_id and top_track.rank <= 3),
    order_by: [:name],
    select: track

query =
  from artist in Artist,
    order_by: artist.artist_id,
    limit: 10,
    preload: [albums: ^album_query],
    preload: [albums: [tracks: ^track_query]]

data = Repo.all(query)
```

Maybe we can even make a helper function to build the window query?

```elixir
defmodule QueryHelper do
  import Ecto.Query

  def partition_limit(queryable, opts) when is_atom(queryable) do
    partition_limit(from(x in queryable), opts)
  end

  def partition_limit(queryable, partition_by: p, order_by: o, limit: l) do
    %{from: %{source: {_, schema}}} = queryable
    [primary_key] = schema.__schema__(:primary_key)

    ranking_query =
      from r in queryable,
        select: %{id: field(r, ^primary_key), rank: row_number() |> over(:w)},
        windows: [w: [partition_by: ^p, order_by: ^o]]

    from row in schema,
      join: top_rows in subquery(ranking_query),
      on: (field(row, ^primary_key) == top_rows.id and top_rows.rank <= ^l),
      select: row
  end
end

query =
  from artist in Artist,
    order_by: artist.artist_id,
    limit: 10,
    select: artist,
    preload: [albums: ^QueryHelper.partition_limit(Album, partition_by: :artist_id, order_by: :title, limit: 1)],
    preload: [albums: [tracks: ^QueryHelper.partition_limit(Track, partition_by: :album_id, order_by: :name, limit: 3)]]

Repo.all(query)
```

How does it perform?

```
[debug] QUERY OK source="Artist" db=2.2ms idle=1513.9ms
[debug] QUERY OK source="Album" db=6.9ms idle=1473.7ms
[debug] QUERY OK source="Track" db=7.3ms idle=1478.2ms
```

Not as good as the joins, but it's nice to have a generic helper for quick queries.


## Solution 5: Preload Query with lateral join

We can also use lateral joins again with preload queries.
The trick here is to start the query with the child schema first,
then join to the parent schema, then laterally to get the top N row ids.


```elixir
album_query =
  from album in Album, as: :album,
    inner_lateral_join: top_album in subquery(
      from Album,
      where: [artist_id: parent_as(:album).artist_id],
      order_by: :title,
      limit: 1,
      select: [:album_id]
    ), on: album.album_id == top_album.album_id

track_query =
  from track in Track, as: :track,
    inner_lateral_join: top_track in subquery(
      from Track,
      where: [album_id: parent_as(:track).album_id],
      order_by: :name,
      limit: 3,
      select: [:track_id]
    ), on: (track.track_id == top_track.track_id)

query =
  from artist in Artist,
    order_by: artist.artist_id,
    limit: 10,
    select: artist,
    preload: [albums: ^album_query],
    preload: [albums: [tracks: ^track_query]]

data = Repo.all(query)
```


How does it perform?

```
[debug] QUERY OK source="Artist" db=4.2ms idle=1482.5ms
[debug] QUERY OK source="Album" db=2.1ms idle=1073.3ms
[debug] QUERY OK source="Track" db=3.1ms idle=1071.6ms
```

Slightly better than the window function.


## Solution 6: Preload Functions

While preload queries can work well, there's another approach to take using lateral joins and CTEs:

```elixir
defmodule Preloads do
  alias Chinook.{Artist, Album, Track, Repo}

  def albums_for_artist(order_by: order_by, limit: limit) do
    fn artist_ids ->
      cte_query =
        "artist"
        |> with_cte("artist", as: fragment("select unnest(? :: int[]) as artist_id", ^artist_ids))

      query =
        from artist in cte_query, as: :artist,
          inner_lateral_join: album in subquery(
            from a in Album,
              where: a.artist_id == parent_as(:artist).artist_id,
              order_by: ^order_by,
              limit: ^limit,
              select: a
            ),
          select: album

      Repo.all(query)
    end
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
end

query =
  from artist in Artist,
    order_by: artist.artist_id,
    limit: 10,
    select: artist,
    preload: [albums: ^Preloads.albums_for_artist(order_by: :title, limit: 1)],
    preload: [albums: [tracks: ^Preloads.tracks_for_album(order_by: :name, limit: 3)]]

Repo.all(query)


cte_query =
  from a in Artist,
  where: a.artist_id < 10,
  select: a

query =
  Album
  |> with_cte("artist", as: ^cte_query)
  |> join(:inner, [album], a in "artist", on: album.artist_id == a.artist_id)
  |> select([album, artist], %{title: album.title, name: artist.name})

```

```
[debug] QUERY OK source="Artist" db=2.9ms idle=872.6ms
[debug] QUERY OK db=2.0ms queue=2.3ms idle=875.8ms
[debug] QUERY OK db=2.2ms queue=1.8ms idle=880.3ms
```
Each query runs very fast, and altogether under 10 ms.

## Conclusion

While the Ecto docs don't tell us exactly how to solve the preload-limit problem*, there are several approaches within the Ecto DSL.
For good performance, using lateral joins with named bindings is the way to go.
If joins are problematic, preload functions using CTEs and lateral joins also gives good performance.
If you need a stand-alone ranking query, then window functions work well, but probably shouldn't be the first option.
