defmodule Chinook.Catalog.TestSchema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern
  use Chinook.Catalog.Graph

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Chinook.Catalog.Loader.add(ChinookRepo)

    ctx
    |> Map.put(:loader, loader)
    |> Map.put(:repo, ChinookRepo)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  import_types(Absinthe.Type.Custom)
  import_types(Chinook.Util.Filter)

  node interface do
    resolve_type(&Chinook.Catalog.Graph.resolve_type/2)
  end

  query do
    node field do
      resolve(&Chinook.Catalog.Graph.resolve_node/2)
    end

    import_fields(:catalog_connections)
  end
end
