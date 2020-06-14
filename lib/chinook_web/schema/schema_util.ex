defmodule ChinookWeb.SchemaUtil do
  require Logger

  def batch(mod, fun, key) do
    batch(mod, fun, [], key)
  end

  def batch(mod, fun, args, key) do
    Absinthe.Resolution.Helpers.batch(
      {mod, fun, args},
      key,
      &{:ok, Map.get(&1, key)}
    )
  end

  def item_cursor(item, %{cursor_field: field}) do
    "#{field}:#{Map.get(item, field)}" |> Base.encode64()
  end

  def decode_cursor(pagination_args = %{after: cursor}, _default_field) do
    [field, value] = cursor |> Base.decode64!() |> String.split(":")
    pagination_args
    |> Map.put(:cursor_field, String.to_existing_atom(field))
    |> Map.put(:after, value)
  end

  def decode_cursor(pagination_args = %{before: cursor}, _default_field) do
    [field, value] = cursor |> Base.decode64!() |> String.split(":")
    pagination_args
    |> Map.put(:cursor_field, String.to_existing_atom(field))
    |> Map.put(:before, value)
  end

  def decode_cursor(pagination_args, default_field) do
    pagination_args
    |> Map.put(:cursor_field, default_field)
  end

  def connection_from_slice(items, pagination_args, opts \\ []) do
    {edges, first, last} = build_cursors(items, pagination_args)

    page_info = %{
      start_cursor: first,
      end_cursor: last,
      has_previous_page: Keyword.get(opts, :has_previous_page, false),
      has_next_page: Keyword.get(opts, :has_next_page, false)
    }

    {:ok, %{edges: edges, page_info: page_info}}
  end

  defp build_cursors([], _pagination_args), do: {[], nil, nil}

  defp build_cursors([item | items], pagination_args) do
    first = item_cursor(item, pagination_args)
    edge = build_edge(item, first)
    {edges, last} = do_build_cursors(items, pagination_args, [edge], first)
    {edges, first, last}
  end

  defp do_build_cursors([], _pagination_args, edges, last), do: {Enum.reverse(edges), last}

  defp do_build_cursors([item | rest], pagination_args, edges, _last) do
    cursor = item_cursor(item, pagination_args)
    edge = build_edge(item, cursor)
    do_build_cursors(rest, pagination_args, [edge | edges], cursor)
  end

  defp build_edge({item, args}, cursor) do
    args
    |> Enum.flat_map(fn
      {key, _} when key in [:cursor, :node] ->
        Logger.warn("Ignoring additional #{key} provided on edge (overriding is not allowed)")
        []
      {key, val} ->
        [{key, val}]
    end)
    |> Enum.into(build_edge(item, cursor))
  end

  defp build_edge(item, cursor) do
    %{
      node: item,
      cursor: cursor
    }
  end

  def connection_batch(mod, fun, pagination_args, key) do
    Absinthe.Resolution.Helpers.batch(
      {mod, fun, pagination_args},
      key,
      fn batch_result ->
        data = Map.get(batch_result, key, [])
        connection_from_slice(data, pagination_args)
      end
    )
  end
end
