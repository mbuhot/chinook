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
      |> paginate(:track, args)
  """
  @spec paginate(Ecto.Queryable.t(), binding :: atom, PagingOptions.t()) :: Ecto.Query.t()
  def paginate(queryable, binding, args) do
    {order, limit} = build_paginate_order_limit(binding, args)

    from(queryable,
      where: ^build_paginate_where(binding, args),
      order_by: ^order,
      limit: ^limit
    )
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

  # Builds the order_by, limit, and where clauses for a paginated query
  defp build_paginate_order_limit(binding, args = %{cursor_field: cursor_field}) do
    case args do
      %{last: n} -> {[desc: dynamic([{^binding, x}], field(x, ^cursor_field))], n}
      %{first: n} -> {[asc: dynamic([{^binding, x}], field(x, ^cursor_field))], n}
      _ -> {[asc: dynamic([{^binding, x}], field(x, ^cursor_field))], nil}
    end
  end

  defp build_paginate_where(binding, args = %{cursor_field: cursor_field}) do
    case args do
      %{after: lower, before: upper} ->
        dynamic(
          [{^binding, x}],
          field(x, ^cursor_field) > ^lower and field(x, ^cursor_field) < ^upper
        )

      %{after: lower} ->
        dynamic([{^binding, x}], field(x, ^cursor_field) > ^lower)

      %{before: upper} ->
        dynamic([{^binding, x}], field(x, ^cursor_field) < ^upper)

      _ ->
        []
    end
  end
end
