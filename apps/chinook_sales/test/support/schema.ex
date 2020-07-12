defmodule Chinook.Sales.TestSchema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Chinook.Catalog.Loader.add(ChinookRepo)
      |> Chinook.Sales.Loader.add(ChinookRepo)

    ctx
    |> Map.put(:loader, loader)
    |> Map.put(:repo, ChinookRepo)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  import_types Absinthe.Type.Custom
  import_types Chinook.Util.Filter
  use Chinook.Sales.Graph
  use Chinook.Catalog.Graph

  node interface do
    resolve_type fn data, res ->
      Chinook.Sales.Graph.resolve_type(data, res) ||
        Chinook.Catalog.Graph.resolve_type(data, res)
    end
  end

  query do
    node field do
      resolve fn data, res ->
        Chinook.Sales.Graph.resolve_node(data, res) ||
          Chinook.Catalog.Graph.resolve_node(data, res)
      end
    end

    import_fields :catalog_connections
    import_fields :sales_connections
  end
end
