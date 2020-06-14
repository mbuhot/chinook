defmodule ChinookWeb.SchemaUtil do
  require Logger

  @doc """
  Decode cursor field and cutoff value from pagination args.

  A default cursor field must be provided, incase neither of :before or :after are given.
  """
  def decode_cursor(pagination_args, default_cursor_field) do
    pagination_args
    |> Map.put(:cursor_field, default_cursor_field)
    |> decode_cursor_arg(:after)
    |> decode_cursor_arg(:before)
  end

  defp decode_cursor_arg(pagination_args, arg) do
    case pagination_args do
      %{^arg => cursor} ->
        [field, value] = cursor |> Base.decode64!() |> String.split(":")
        pagination_args
        |> Map.put(:cursor_field, String.to_existing_atom(field))
        |> Map.put(arg, value)

      _ -> pagination_args
    end
  end


  @doc """
  Shorthand over Absinthe.Resolution.Helpers.batch
  """
  def batch(mod, fun, args \\ [], key) do
    Absinthe.Resolution.Helpers.batch(
      {mod, fun, args},
      key,
      &{:ok, Map.get(&1, key)}
    )
  end

  @doc """
  Batch resolution for relay connection fields

  Works like Absinthe.Resolution.Helpers.batch, converting the
  result of the batch result into connection using connection_from_slice/2
  """
  def connection_batch(pagination_args, mod, fun, key) do
    Absinthe.Resolution.Helpers.batch(
      {mod, fun, pagination_args},
      key,
      fn batch_result ->
        data = Map.get(batch_result, key, [])
        connection_from_slice(data, pagination_args)
      end
    )
  end

  @doc """
  Convert a list of items and pagination args into Relay connection

  A cursor will be generated for each item, based on `pagination_args.cursor_field`
  """
  def connection_from_slice(items, pagination_args, opts \\ []) do
    items = items |> Enum.sort_by(&Map.get(&1, pagination_args.cursor_field))
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

  defp item_cursor(item, %{cursor_field: field}) do
    "#{field}:#{Map.get(item, field)}" |> Base.encode64()
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
end
