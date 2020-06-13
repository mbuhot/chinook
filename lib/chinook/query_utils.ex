defmodule Chinook.QueryUtils do
  import Ecto.Query

  @spec top_n(module, atom, [opt]) :: Ecto.Query.t()
        when opt:
               {:where, Ecto.Query.dynamic()}
               | {:order_by, any}
               | {:limit, integer}
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
      order_by: ^order_by
  end

  @type pagination_args :: %{
          optional(:first) => integer,
          optional(:last) => integer,
          optional(:before) => integer,
          optional(:after) => integer
        }

  @spec cursor_assoc(
          schema :: module,
          assoc :: atom,
          cursor_fied :: atom,
          args :: pagination_args
        ) :: Ecto.Query.t()
  def cursor_assoc(schema, assoc, cursor_field, args) do
    {order_by, limit, where} = cursor_params(cursor_field, args)
    top_n(schema, assoc, where: where, order_by: order_by, limit: limit)
  end

  @spec cursor_by(
          schema :: module,
          cursor_field :: atom,
          args :: pagination_args
        ) :: Ecto.Query.t()
  def cursor_by(schema, cursor_field, args) do
    {order_by, limit, where} = cursor_params(cursor_field, args)
    from schema, where: ^where, order_by: ^order_by, limit: ^limit
  end

  @spec cursor_params(
          cursor_field :: atom,
          args :: pagination_args
        ) :: {order_by :: any, limit :: integer, where :: [] | Ecto.Query.dynamic()}
  defp cursor_params(cursor_field, %{last: limit, before: cutoff}) do
    where = dynamic([a], field(a, ^cursor_field) < ^cutoff)
    {[desc: cursor_field], limit, where}
  end

  defp cursor_params(cursor_field, %{last: limit}) do
    {[desc: cursor_field], limit, []}
  end

  defp cursor_params(cursor_field, %{first: limit, after: cutoff}) do
    where = dynamic([a], field(a, ^cursor_field) > ^cutoff)
    {[asc: cursor_field], limit, where}
  end

  defp cursor_params(cursor_field, args) do
    {[asc: cursor_field], Map.get(args, :first), []}
  end
end
