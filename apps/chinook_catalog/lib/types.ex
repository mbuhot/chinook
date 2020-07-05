defmodule Chinook.Catalog.Types do
  defmacro __using__(_opts) do
    quote do
      import_types Chinook.Catalog.Album.Schema
      import_types Chinook.Catalog.Artist.Schema
      import_types Chinook.Catalog.Connections
      import_types Chinook.Catalog.Genre.Schema
      import_types Chinook.Catalog.Playlist.Schema
      import_types Chinook.Catalog.Track.Schema
    end
  end
end
