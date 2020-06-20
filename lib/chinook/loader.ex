defmodule Chinook.Loader do
  def data() do
    Dataloader.new()
    |> Dataloader.add_source(Chinook.Artist.Loader, Chinook.Artist.Loader.new())
    |> Dataloader.add_source(Chinook.Album.Loader, Chinook.Album.Loader.new())
    |> Dataloader.add_source(Chinook.Track.Loader, Chinook.Track.Loader.new())
    |> Dataloader.add_source(Chinook.Genre.Loader, Chinook.Genre.Loader.new())
    |> Dataloader.add_source(Chinook.Playlist.Loader, Chinook.Playlist.Loader.new())
    |> Dataloader.add_source(Chinook.Employee.Loader, Chinook.Employee.Loader.new())
  end
end
