defmodule Chinook.Catalog.Loader do
  alias Chinook.Catalog.{Album, Artist, Genre, Playlist, Track}

  def add(loader) do
    loader
    |> Dataloader.add_source(
      __MODULE__,
      Dataloader.Ecto.new(ChinookRepo,
        query: fn
          Album, args -> Album.Loader.query(args)
          Artist, args -> Artist.Loader.query(args)
          Genre, args -> Genre.Loader.query(args)
          Playlist, args -> Playlist.Loader.query(args)
          Track, args -> Track.Loader.query(args)
        end
      )
    )
  end
end
