defmodule ChinookWeb.Relay do
  @doc """
  Resolve a Relay connection

  ## Example

    connection field :artists, node_type: :artist do
      resolve(fn
        pagination_args, _ ->
          Relay.resolve_connection({Artist.Resolvers, :cursor, pagination_args}, cursor_field: :artist_id)
      end)
    end
  """
  def resolve_connection({mod, fun, pagination_args}, cursor_field: cursor_field) do
    pagination_args = decode_cursor(pagination_args, cursor_field)
    data = apply(mod, fun, [pagination_args])
    connection_from_slice(data, pagination_args)
  end

  @doc """
  Resolve a Relay connection with batching

  ## Example

      connection field :albums, node_type: :album do
        resolve(fn pagination_args, %{source: artist} ->
          Relay.resolve_connection_batch(
            {Album.Resolvers, :albums_for_artist_ids, pagination_args},
            cursor_field: :album_id,
            batch_key: artist.artist_id
          )
        end)
      end
  """
  def resolve_connection_batch({mod, fun, pagination_args},
        cursor_field: cursor_field,
        batch_key: batch_key
      ) do
    pagination_args = decode_cursor(pagination_args, cursor_field)

    Absinthe.Resolution.Helpers.batch(
      {mod, fun, pagination_args},
      batch_key,
      fn batch_result ->
        data = Map.get(batch_result, batch_key, [])
        connection_from_slice(data, pagination_args)
      end
    )
  end

  defp decode_cursor(pagination_args, default_cursor_field) do
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

      _ ->
        pagination_args
    end
  end

  defp connection_from_slice(items, pagination_args, opts \\ []) do
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

  defp build_edge(item, cursor) do
    %{
      node: item,
      cursor: cursor
    }
  end
end
