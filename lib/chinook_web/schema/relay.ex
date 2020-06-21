defmodule ChinookWeb.Relay do
  @doc """
  Resolve an `id` field from the primary key of an Ecto schema
  """
  def id(x, _resolution) do
    Map.get(x, hd(x.__struct__.__schema__(:primary_key)))
  end

  @doc """
  Resolve a Relay connection

  Note this should only be used for top-level fields in the schema.
  Connection fields defined within object types should use `connection_dataloader`.

  ## Example

    connection field :artists, node_type: :artist do
      arg :by, :artist_sort_order, default_value: :artist_id
      arg :filter, :artist_filter, default_value: %{}

      resolve fn args, _resolution ->
        Relay.resolve_connection(Artist.Resolvers, :page, args)
      end
    end
  """
  def resolve_connection(mod, fun, args) do
    args = decode_cursor(args)
    data = apply(mod, fun, [args])
    connection_from_slice(data, args)
  end

  @doc """
  Resolve a Relay Connection from a Dataloader.Ecto source.

  Parameters:

   - source: The name of the Dataloader source to use
   - argsfn: callback receiving (parent, arg, resolution) and returning {schema, args, [{foreign_key, value}]}

  ## Example

      connection field :invoices, node_type: :invoice do
        arg :by, :invoice_sort_order, default_value: :invoice_id
        arg :filter, :invoice_filter, default_value: %{}
        middleware Scope, [read: :invoice]
        resolve Relay.connection_dataloader(
          Chinook.Invoice.Loader,
          fn customer, args, _res -> {Chinook.Invoice, args, customer_id: customer.customer_id} end
        )
      end
  """
  def connection_dataloader(source, argsfn) do
    fn parent, args, res = %{context: %{loader: loader}} ->
      args = decode_cursor(args)
      {schema, args, [{foreign_key, val}]} = argsfn.(parent, args, res)

      loader
      |> Dataloader.load(source, {{:many, schema}, args}, [{foreign_key, val}])
      |> Absinthe.Resolution.Helpers.on_load(fn loader ->
        loader
        |> Dataloader.get(source, {{:many, schema}, args}, [{foreign_key, val}])
        |> connection_from_slice(args)
      end)
    end
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

  def connection_from_slice(items, pagination_args, opts \\ []) do
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
