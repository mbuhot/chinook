defmodule Chinook.GraphQL.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern
  require Logger

  def dataloader() do
    Dataloader.new()
    |> Chinook.Catalog.Loader.add(ChinookRepo)
    |> Chinook.Sales.Loader.add(ChinookRepo)
  end

  def context(ctx) do
    dataloader = dataloader()
    {:ok, async_loader} = Chinook.Loader.Server.start_link(dataloader)

    ctx
    |> Map.put(:loader, dataloader)
    |> Map.put(:async_loader, async_loader)
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
