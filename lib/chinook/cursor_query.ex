defmodule Chinook.CursorQuery do
  import Ecto.Query

  @doc """
  Get a page of associated items for a schema and association

  ## Example

      Artist
      |> CursorQuery.cursor_assoc(:albums, args)
      |> Repo.all()
  """
  @spec cursor_assoc(schema :: module, assoc :: atom, args :: PagingOptions.t()) :: Ecto.Query.t()
  def cursor_assoc(schema, assoc, args) do
    {order_by, limit, where} = cursor_params(args)
    assoc_info = schema.__schema__(:association, assoc)
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
      order_by: ^order_by
  end

  @doc """
  Get a page of items for a schema

  ## Example

      Artist
      |> CursorQuery.cursor_by(args)
      |> Repo.all()
  """
  @spec cursor_by(schema :: module, args :: PagingOptions.t()) :: Ecto.Query.t()
  def cursor_by(schema, args) do
    {order_by, limit, where} = cursor_params(args)
    from schema, where: ^where, order_by: ^order_by, limit: ^limit
  end

  @doc """
  Get a page of items per batch key provided

  ## Example

      Album
      |> CursorQuery.cursor_batch(args, partition_by: :artist_id, partition_keys: [1,2,3])
      |> Repo.all()
  """
  @spec cursor_batch(schema :: module, args :: PagingOptions.t(), [opt]) :: Ecto.Query.t()
        when opt: {:partition_by, atom} | {:partition_keys, [integer]}
  def cursor_batch(schema, args, partition_by: key_field, partition_keys: partition_keys) do
    {order_by, limit, where} = cursor_params(args)

    outer_query =
      "partition_keys"
      |> with_cte("partition_keys",
        as: fragment("select unnest(? :: int[]) as partition_key", ^partition_keys)
      )

    inner_query =
      from row in schema,
        where: field(row, ^key_field) == parent_as(:partition).partition_key,
        where: ^where,
        limit: ^limit,
        order_by: ^order_by,
        select: row

    from batch in outer_query, as: :partition,
      inner_lateral_join: row in subquery(inner_query),
      select: row
  end

  defp cursor_params(args = %{cursor_field: cursor_field}) do
    {order, limit} =
      case args do
        %{last: n} -> {[desc: cursor_field], n}
        %{first: n} -> {[asc: cursor_field], n}
        _ -> {[asc: cursor_field], nil}
      end

    where =
      case args do
        %{after: lower, before: upper} ->
          dynamic([x], field(x, ^cursor_field) > ^lower and field(x, ^cursor_field) < ^upper)

        %{after: lower} ->
          dynamic([x], field(x, ^cursor_field) > ^lower)

        %{before: upper} ->
          dynamic([x], field(x, ^cursor_field) < ^upper)

        _ ->
          []
      end

    {order, limit, where}
  end
end
