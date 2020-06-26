defmodule Chinook.Loader do
  alias Chinook.{Album, Artist, Customer, Employee, Genre, Invoice, Playlist, Track}

  def data() do
    Dataloader.new()
    |> Dataloader.add_source(
      Chinook.Loader,
      Dataloader.Ecto.new(Chinook.Repo,
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
