defmodule ChinookWeb.Relay do
  @doc """
  Resolve a Relay connection

  Note this should only be used for top-level fields in the schema.
  Connection fields defined within object types should use `resolve_connection_batch/2`.

  ## Example

    connection field :artists, node_type: :artist do
      arg :by, :artist_sort_order

      resolve(fn
        args, _ ->
          args = Map.put_new(args, :by, :artist_id)
          Relay.resolve_connection({Artist.Resolvers, :resolve_connection, args})
      end)
    end
  """
  def resolve_connection({mod, fun, pagination_args}) do
    pagination_args = decode_cursor(pagination_args)
    data = apply(mod, fun, [pagination_args])
    connection_from_slice(data, pagination_args)
  end

  @doc """
  Resolve a Relay connection with batching

  ## Example

      connection field :albums, node_type: :album do
        arg :by, :album_sort_order

        resolve(fn args, %{source: artist} ->
          args = Map.put(args, :by, :album_id)

          Relay.resolve_connection_batch(
            {Album.Resolvers, :albums_for_artist_ids, args},
            batch_key: artist.artist_id
          )
        end)
      end
  """
  def resolve_connection_batch({mod, fun, pagination_args}, batch_key: batch_key) do
    pagination_args = decode_cursor(pagination_args)

    Absinthe.Resolution.Helpers.batch(
      {mod, fun, pagination_args},
      batch_key,
      &connection_from_slice(Map.get(&1, batch_key, []), pagination_args)
    )
  end

  defp decode_cursor(pagination_args) do
    pagination_args
    |> decode_cursor_arg(:after)
    |> decode_cursor_arg(:before)
  end

  defp decode_cursor_arg(pagination_args, arg) do
    case pagination_args do
      %{^arg => cursor} ->
        [field, value] = cursor |> Base.decode64!() |> String.split(":", parts: 2)

        pagination_args
        |> Map.put(:by, String.to_existing_atom(field))
        |> Map.put(arg, value)

      _ ->
        pagination_args
    end
  end

  defp connection_from_slice(items, pagination_args, opts \\ []) do
    items = items |> Enum.sort_by(&Map.get(&1, pagination_args.by))
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

  defp item_cursor(item, %{by: field}) do
    "#{field}:#{Map.get(item, field)}" |> Base.encode64()
  end

  defp build_edge(item, cursor) do
    %{
      node: item,
      cursor: cursor
    }
  end
end
