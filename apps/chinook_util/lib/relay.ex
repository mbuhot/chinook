defmodule Chinook.Util.Relay do
  @doc """
  Resolve an `id` field from the primary key of an Ecto schema
  """
  @spec id(Ecto.Schema.t(), Absinthe.Resolution.t()) :: any
  def id(x, _resolution) do
    [{_, id}] = Ecto.primary_key!(x)
    id
  end

  def node_dataloader(loader, source, schema, id) do
    loader
    |> Dataloader.load(source, schema, id)
    |> Absinthe.Resolution.Helpers.on_load(fn loader ->
      result = Dataloader.get(loader, source, schema, id)
      {:ok, result}
    end)
  end

  @doc """
  Resolve a Relay connection using a query function

  Note this should only be used for top-level fields in the schema.
  Connection fields defined within object types should use `connection_dataloader`.

  Requires a `:repo` in the resolution context to use for executing the query.

  ## Example

    connection field :artists, node_type: :artist do
      arg :by, :artist_sort_order, default_value: :artist_id
      arg :filter, :artist_filter, default_value: %{}

      resolve Relay.connection_from_query(&Artist.Loader.query/1, args)
    end
  """
  def connection_from_query(queryfn) do
    fn args, %{context: %{repo: repo}} ->
      args = decode_cursor(args)
      data = args |> queryfn.() |> repo.all()
      connection_from_slice(data, args)
    end
  end

  @doc """
  Resolve a Relay Connection from a Dataloader.Ecto source.

  Parameters:

   - source: The name of the Dataloader source to use
   - argsfn: callback receiving (parent, arg, resolution) and returning {schema, args, [{foreign_key, value}]} or {association, args, parent}

  ## Using explicit foreign key

      connection field :invoices, node_type: :invoice do
        arg :by, :invoice_sort_order, default_value: :invoice_id
        arg :filter, :invoice_filter, default_value: %{}
        middleware Scope, [read: :invoice]
        resolve Relay.connection_dataloader(
          Chinook.Loader,
          fn customer, args, _res -> {Chinook.Invoice, args, customer_id: customer.customer_id} end
        )
      end

  ## Using association

      connection field :invoices, node_type: :invoice do
        arg :by, :invoice_sort_order, default_value: :invoice_id
        arg :filter, :invoice_filter, default_value: %{}
        middleware Scope, [read: :invoice]
        resolve Relay.connection_dataloader(Chinook.Loader, fn customer, args, _res -> {:invoices, args, customer} end)
      end
  """
  def connection_dataloader(source, argsfn) when is_function(argsfn) do
    fn parent, args, res = %{context: %{loader: loader}} ->
      args = decode_cursor(args)

      {batch_key, batch_value} =
        case argsfn.(parent, args, res) do
          {schema, args, [{foreign_key, val}]} ->
            {{{:many, schema}, args}, [{foreign_key, val}]}

          {assoc, args, parent} when is_atom(assoc) and is_struct(parent) ->
            {{assoc, args}, parent}
        end

      loader
      |> Dataloader.load(source, batch_key, batch_value)
      |> Absinthe.Resolution.Helpers.on_load(fn loader ->
        loader
        |> Dataloader.get(source, batch_key, batch_value)
        |> connection_from_slice(args)
      end)
    end
  end

  @doc """
  Resolve a connection using dataloader and an Ecto association that
  matches the name of the field being resolved.

  # Example

      connection field :invoices, node_type: :invoice do
        arg :by, :invoice_sort_order, default_value: :invoice_id
        arg :filter, :invoice_filter, default_value: %{}
        middleware Scope, [read: :invoice]
        resolve Relay.connection_dataloader(Chinook.Loader)
      end
  """
  def connection_dataloader(source) do
    connection_dataloader(source, fn parent, args, res ->
      resource = res.definition.schema_node.identifier
      {resource, args, parent}
    end)
  end

  defp decode_cursor(pagination_args) do
    pagination_args
    |> decode_cursor_arg(:after)
    |> decode_cursor_arg(:before)
  end

  defp decode_cursor_arg(pagination_args, arg) do
    case pagination_args do
      %{^arg => cursor} ->
        [by, pk, id] = cursor |> Base.decode64!() |> String.split("|", parts: 3)

        pagination_args
        |> Map.put(:by, String.to_existing_atom(by))
        |> Map.put(arg, [{String.to_existing_atom(pk), id}])

      _ ->
        pagination_args
    end
  end

  def connection_from_slice(items, pagination_args) do
    items =
      case pagination_args do
        %{last: _} -> Enum.reverse(items)
        _ -> items
      end

    count = Enum.count(items)
    {edges, first, last} = build_cursors(items, pagination_args)

    # TODO: use a protocol for `row_count` instead of assuming field available
    row_count =
      case items do
        [] -> 0
        [%{row_count: n} | _rest] -> n
      end

    page_info = %{
      start_cursor: first,
      end_cursor: last,
      has_previous_page:
        case pagination_args do
          %{after: _} -> true
          %{last: ^count} -> row_count > count
          _ -> false
        end,
      has_next_page:
        case pagination_args do
          %{before: _} -> true
          %{first: ^count} -> row_count > count
          _ -> false
        end
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
    [pk] = item.__struct__.__schema__(:primary_key)
    "#{field}|#{pk}|#{Map.get(item, pk)}" |> Base.encode64()
  end

  defp build_edge(item, cursor) do
    %{
      node: item,
      cursor: cursor
    }
  end
end