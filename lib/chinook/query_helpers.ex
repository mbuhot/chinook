defmodule Chinook.QueryHelpers do
  import Ecto.Query

  alias Chinook.PagingOptions

  @doc """
  Apply pagination to a query using a named binding.

  The named binding is useful when the cursor field is not on the first
  binding in the queryable.

  ## Example

      from(playlist_track in PlaylistTrack, as: :playlist_track,
        join: track in assoc(playlist_track, :track), as: :track,
        select: track
      )
      |> paginate(Track, :track, args)
  """
  @spec paginate(Ecto.Queryable.t(), module, binding :: atom, PagingOptions.t()) :: Ecto.Query.t()
  def paginate(query, schema, binding, args) do
    query
    |> paginate_where(binding, args)
    |> paginate_order_limit(schema, binding, args)
    |> select_row_count(args)
  end

  @doc """
  Run the given query as a inner lateral join for each value of batch_ids

  The returned query is a join with two named bindings, `:batch` and `:batch_data`

  ## Example

      from(playlist_track in PlaylistTrack, as: :playlist_track,
        join: track in assoc(playlist_track, :track), as: :track,
        select: track
      )
      |> paginate(:track, args)
      |> batch_by(:playlist_track, :playlist_id, playlist_ids)
      |> select([playlist, track], {playlist.id, track})
  """
  def batch_by(queryable, binding, batch_field, batch_ids) do
    batch_cte =
      "batch"
      |> with_cte("batch", as: fragment("select unnest(? :: int[]) as id", ^batch_ids))

    queryable =
      queryable
      |> where(
        [{^binding, batch_child}],
        field(batch_child, ^batch_field) == parent_as(:batch).id
      )

    from(batch in batch_cte,
      as: :batch,
      inner_lateral_join: batch_child in subquery(queryable),
      as: :batch_data
    )
  end

  @doc """
  Apply filters to a string field
  """
  def filter_string(queryable, field, filters) do
    Enum.reduce(filters, queryable, fn
      {:like, pattern}, queryable ->
        where(queryable, [x], like(field(x, ^field), ^pattern))

      {:starts_with, prefix}, queryable ->
        where(queryable, [x], like(field(x, ^field), ^"#{prefix}%"))

      {:ends_with, suffix}, queryable ->
        where(queryable, [x], like(field(x, ^field), ^"%#{suffix}"))
    end)
  end

  @doc """
  Apply filters to a numeric field
  """
  def filter_number(queryable, field, filters) do
    Enum.reduce(filters, queryable, fn
      {:gt, val}, queryable -> where(queryable, [x], field(x, ^field) > ^val)
      {:gte, val}, queryable -> where(queryable, [x], field(x, ^field) >= ^val)
      {:eq, val}, queryable -> where(queryable, [x], field(x, ^field) == ^val)
      {:ne, val}, queryable -> where(queryable, [x], field(x, ^field) != ^val)
      {:lt, val}, queryable -> where(queryable, [x], field(x, ^field) < ^val)
      {:lte, val}, queryable -> where(queryable, [x], field(x, ^field) <= ^val)
    end)
  end

  @doc """
  Apply filters to a datetime field
  """
  def filter_datetime(queryable, field, filters) do
    Enum.reduce(filters, queryable, fn
      {:before, val}, queryable -> where(queryable, [x], field(x, ^field) < ^val)
      {:after, val}, queryable -> where(queryable, [x], field(x, ^field) >= ^val)
    end)
  end

  # Adds the order_by, limit, and where clauses for a paginated query
  defp paginate_order_limit(queryable, schema, binding, args = %{by: cursor_field}) do
    [pk] = schema.__schema__(:primary_key)

    case args do
      %{last: n} ->
        queryable
        |> order_by([{^binding, x}], desc: field(x, ^cursor_field), desc: field(x, ^pk))
        |> limit(^n)

      %{first: n} ->
        queryable
        |> order_by([{^binding, x}], asc: field(x, ^cursor_field), asc: field(x, ^pk))
        |> limit(^n)

      _ ->
        queryable
        |> order_by([{^binding, x}], asc: field(x, ^cursor_field), asc: field(x, ^pk))
    end
  end

  defp paginate_where(queryable, binding, args = %{by: by}) do
    case args do
      %{after: [{key_field, lower}], before: [{key_field, upper}]} ->
        queryable
        |> add_lower_bound(binding, lower, key_field, by)
        |> add_upper_bound(binding, upper, key_field, by)

      %{after: [{key_field, lower}]} ->
        queryable
        |> add_lower_bound(binding, lower, key_field, by)

      %{before: [{key_field, upper}]} ->
        queryable
        |> add_upper_bound(binding, upper, key_field, by)

      _ ->
        queryable
    end
  end

  defp add_upper_bound(queryable, binding, upper_id, key_field, key_field) do
    queryable
    |> where([{^binding, x}], field(x, ^key_field) < ^upper_id)
  end

  defp add_upper_bound(queryable, binding, upper_id, key_field, sort_field) do
    agg_query = bound_query(queryable)

    upper_bound =
      agg_query
      |> where([{^binding, x}], field(x, ^key_field) == ^upper_id)
      |> select([{^binding, x}], map(x, ^[key_field, sort_field]))

    queryable
    |> with_cte("upper_bound", as: ^upper_bound)
    |> join(:inner, [], "upper_bound", as: :upper_bound)
    |> where(
      [{^binding, x}, {:upper_bound, ub}],
      field(x, ^sort_field) <= field(ub, ^sort_field) and
        field(x, ^key_field) < field(ub, ^key_field)
    )
  end

  defp add_lower_bound(queryable, binding, lower_id, key_field, key_field) do
    queryable
    |> where([{^binding, x}], field(x, ^key_field) > ^lower_id)
  end

  defp add_lower_bound(queryable, binding, lower_id, key_field, sort_field) do
    agg_query = bound_query(queryable)

    lower_bound =
      agg_query
      |> where([{^binding, x}], field(x, ^key_field) == ^lower_id)
      |> select([{^binding, x}], map(x, ^[key_field, sort_field]))

    queryable
    |> with_cte("lower_bound", as: ^lower_bound)
    |> join(:inner, [], "lower_bound", as: :lower_bound)
    |> where(
      [{^binding, x}, {:lower_bound, ub}],
      field(x, ^sort_field) >= field(ub, ^sort_field) and
        field(x, ^key_field) > field(ub, ^key_field)
    )
  end

  defp bound_query(queryable) do
    queryable
    |> Ecto.Queryable.to_query()
    |> exclude(:limit)
    |> exclude(:offset)
    |> exclude(:where)
    |> limit(1)
  end

  defp select_row_count(queryable, args) do
    limit = args[:first] || args[:last]

    case limit do
      nil ->
        queryable

      _ ->
        queryable
        |> select([x], %{x | row_count: count() |> over()})
    end
  end
end
