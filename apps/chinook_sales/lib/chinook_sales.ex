defmodule Chinook.Sales do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Chinook.Catalog.Loader.add()
      |> Chinook.Sales.Loader.add()

    ctx
    |> Map.put(:loader, loader)
    |> Map.put(:repo, ChinookRepo)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  import_types Absinthe.Type.Custom
  import_types Chinook.Util.Filter
  use Chinook.Sales.Types
  use Chinook.Catalog.Types

  node interface do
    resolve_type fn data, res ->
      Chinook.Sales.Node.resolve_type(data, res) ||
        Chinook.Catalog.Node.resolve_type(data, res)
    end
  end

  query do
    node field do
      resolve fn data, res ->
        Chinook.Sales.Node.resolve_node(data, res) ||
          Chinook.Catalog.Node.resolve_node(data, res)
      end
    end

    import_fields :catalog_connections
    import_fields :sales_connections
  end
end
