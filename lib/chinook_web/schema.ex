defmodule ChinookWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias ChinookWeb.Schema.Album
  alias ChinookWeb.Schema.Artist
  alias ChinookWeb.Schema.Genre
  alias ChinookWeb.Schema.Track
  alias ChinookWeb.SchemaUtil

  import_types(Album)
  import_types(Artist)
  import_types(Genre)
  import_types(Track)

  node interface do
    resolve_type fn
      %Chinook.Artist{}, _ -> :artist
      %Chinook.Album{}, _ -> :album
      %Chinook.Track{}, _ -> :track
      %Chinook.Genre{}, _ -> :genre
      _, _ -> nil
    end
  end

  connection node_type: :artist
  connection node_type: :album
  connection node_type: :track
  connection node_type: :genre

  query do
    node field do
      resolve fn
        %{type: :artist, id: id}, resolution ->
          {:ok, Artist.Resolvers.by_id(id, resolution)}

        %{type: :album, id: id}, resolution ->
          {:ok, Album.Resolvers.by_id(id, resolution)}

        %{type: :track, id: id}, resolution ->
          {:ok, Track.Resolvers.by_id(id, resolution)}

        %{type: :genre, id: id}, resolution ->
          {:ok, Genre.Resolvers.by_id(id, resolution)}
      end
    end


    @desc "Cursor over artists"
    connection field :artists, node_type: :artist do
      resolve fn
        pagination_args, _ ->
          pagination_args = pagination_args |> SchemaUtil.decode_cursor(:artist_id)

          pagination_args
          |> Artist.Resolvers.cursor()
          |> SchemaUtil.connection_from_slice(pagination_args)
      end
    end

    @desc "Cursor over genres"
    connection field :genres, node_type: :genre do
      resolve fn
        pagination_args, _ ->
          pagination_args = pagination_args |> SchemaUtil.decode_cursor(:genre_id)

          pagination_args
          |> Genre.Resolvers.cursor()
          |> SchemaUtil.connection_from_slice(pagination_args)
      end
    end
  end
end
