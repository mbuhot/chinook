defmodule Chinook.QueryHelpers do
  import Ecto.Query

  alias Chinook.PagingOptions

  @doc """
  Builds a select clause from requested fields.
  """
  @spec select_fields(Ecto.Queryable.t(), schema :: module, binding :: atom, fields :: [atom] | nil) :: Ecto.Query.t()
  def select_fields(query, _schema, _binding, nil) do
    query
  end

  def select_fields(query, schema, binding, fields) do
    pk_fields = schema.__schema__(:primary_key)
    fk_fields =
      schema.__schema__(:associations)
      |> Enum.map(& schema.__schema__(:association, &1))
      |> Enum.filter(&match?(%Ecto.Association.BelongsTo{}, &1))
      |> Enum.map(& &1.owner_key)

    basic_fields = schema.__schema__(:fields)
    fields = Enum.filter(fields, & &1 in basic_fields)
    selected_fields = Enum.uniq(fields ++ pk_fields ++ fk_fields)

    query
    |> select([{^binding, x}], struct(x, ^selected_fields))
  end

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
    paginate(query, schema, binding, binding, args)
  end

  @doc """
  Similar to paginate/4, but allows for sorting by a joined association.

  ## Example

      # Last 10 tracks by artist name
      Track
      |> from(as: :track)
      |> join(:inner, [track: t], assoc(t, :artist), as: :artist)
      |> paginate(Track, :track, :artist, %{last: 10, by: :name})
  """
  @spec paginate(Ecto.Queryable.t(), module, key_binding :: atom, sort_binding :: atom, PagingOptions.t()) :: Ecto.Query.t()
  def paginate(query, schema, key_binding, sort_binding, args) do
    query
    |> paginate_where(key_binding, sort_binding, args)
    |> paginate_order_limit(schema, key_binding, sort_binding, args)
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
  defp paginate_order_limit(queryable, schema, key_binding, sort_binding, args = %{by: cursor_field}) do
    [pk] = schema.__schema__(:primary_key)

    case args do
      %{last: n} ->
        queryable
        |> order_by([{^key_binding, x}, {^sort_binding, y}], desc: field(y, ^cursor_field), desc: field(x, ^pk))
        |> limit(^n)

      %{first: n} ->
        queryable
        |> order_by([{^key_binding, x}, {^sort_binding, y}], asc: field(y, ^cursor_field), asc: field(x, ^pk))
        |> limit(^n)

      _ ->
        queryable
        |> order_by([{^key_binding, x}, {^sort_binding, y}], asc: field(y, ^cursor_field), asc: field(x, ^pk))
    end
  end

  defp paginate_where(queryable, key_binding, sort_binding, args = %{by: by}) do
    case args do
      %{after: [{key_field, lower}], before: [{key_field, upper}]} ->
        queryable
        |> add_lower_bound(key_binding, sort_binding, lower, key_field, by)
        |> add_upper_bound(key_binding, sort_binding, upper, key_field, by)

      %{after: [{key_field, lower}]} ->
        queryable
        |> add_lower_bound(key_binding, sort_binding, lower, key_field, by)

      %{before: [{key_field, upper}]} ->
        queryable
        |> add_upper_bound(key_binding, sort_binding, upper, key_field, by)

      _ ->
        queryable
    end
  end

  defp add_upper_bound(queryable, key_binding, _sort_binding, upper_id, key_field, key_field) do
    queryable
    |> where([{^key_binding, x}], field(x, ^key_field) < ^upper_id)
  end

  defp add_upper_bound(queryable, key_binding, sort_binding, upper_id, key_field, sort_field) do
    agg_query = bound_query(queryable)

    upper_bound =
      agg_query
      |> where([{^key_binding, x}], field(x, ^key_field) == ^upper_id)
      |> select([{^key_binding, x}], map(x, ^[key_field]))
      |> select_merge([{^sort_binding, y}], map(y, ^[sort_field]))

    queryable
    |> with_cte("upper_bound", as: ^upper_bound)
    |> join(:inner, [], "upper_bound", as: :upper_bound)
    |> where(
      [{^key_binding, x}, {^sort_binding, y}, {:upper_bound, ub}],
      field(y, ^sort_field) < field(ub, ^sort_field) or
        (field(y, ^sort_field) == field(ub, ^sort_field) and
           field(x, ^key_field) < field(ub, ^key_field))
    )
  end

  defp add_lower_bound(queryable, key_binding, _sort_binding, lower_id, key_field, key_field) do
    queryable
    |> where([{^key_binding, x}], field(x, ^key_field) > ^lower_id)
  end

  defp add_lower_bound(queryable, key_binding, sort_binding, lower_id, key_field, sort_field) do
    agg_query = bound_query(queryable)

    lower_bound =
      agg_query
      |> where([{^key_binding, x}], field(x, ^key_field) == ^lower_id)
      |> select([{^key_binding, x}], map(x, ^[key_field]))
      |> select_merge([{^sort_binding, y}], map(y, ^[sort_field]))

    queryable
    |> with_cte("lower_bound", as: ^lower_bound)
    |> join(:inner, [], "lower_bound", as: :lower_bound)
    |> where(
      [{^key_binding, x}, {^sort_binding, y}, {:lower_bound, lb}],
      field(y, ^sort_field) > field(lb, ^sort_field) or
        (field(y, ^sort_field) == field(lb, ^sort_field) and
           field(x, ^key_field) > field(lb, ^key_field))
    )
  end

  defp bound_query(queryable) do
    queryable
    |> Ecto.Queryable.to_query()
    |> exclude(:select)
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
        |> select_merge([x], %{x | row_count: count() |> over()})
    end
  end
end
