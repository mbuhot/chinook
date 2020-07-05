defmodule Chinook.Loader do
  alias Chinook.Catalog.{Album, Artist, Genre, Playlist, Track}
  alias Chinook.Sales.{Customer, Employee, Invoice}

  def data() do
    Dataloader.new()
    |> Dataloader.add_source(
      Chinook.Loader,
      Dataloader.Ecto.new(ChinookRepo,
        query: fn
          Album, args -> Album.Loader.query(args)
          Artist, args -> Artist.Loader.query(args)
          Customer, args -> Customer.Loader.query(args)
          Employee, args -> Employee.Loader.query(args)
          Genre, args -> Genre.Loader.query(args)
          Invoice, args -> Invoice.Loader.query(args)
          Invoice.Line, _args -> Invoice.Line
          Playlist, args -> Playlist.Loader.query(args)
          Track, args -> Track.Loader.query(args)
        end
      )
    )
  end
end
