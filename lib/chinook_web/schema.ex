defmodule ChinookWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias Absinthe.Relay.Node.ParseIDs
  alias ChinookWeb.Schema.Album
  alias ChinookWeb.Schema.Artist
  alias ChinookWeb.Schema.Customer
  alias ChinookWeb.Schema.Employee
  alias ChinookWeb.Schema.Filter
  alias ChinookWeb.Schema.Genre
  alias ChinookWeb.Schema.Invoice
  alias ChinookWeb.Schema.Playlist
  alias ChinookWeb.Schema.Track
  alias ChinookWeb.Scope

  def context(ctx) do
    ctx
    |> Map.put(:loader, Chinook.Loader.data())
    |> Map.put(:repo, Chinook.Repo)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  import_types Absinthe.Type.Custom
  import_types Album
  import_types Artist
  import_types Customer
  import_types Employee
  import_types Filter
  import_types Genre
  import_types Invoice
  import_types Playlist
  import_types Track

  node interface do
    resolve_type fn
      %Chinook.Album{}, _ -> :album
      %Chinook.Artist{}, _ -> :artist
      %Chinook.Customer{}, _ -> :customer
      %Chinook.Employee{}, _ -> :employee
      %Chinook.Genre{}, _ -> :genre
      %Chinook.Invoice{}, _ -> :invoice
      %Chinook.Playlist{}, _ -> :playlist
      %Chinook.Track{}, _ -> :track
      _, _ -> nil
    end
  end

  connection node_type: :album
  connection node_type: :artist
  connection node_type: :customer
  connection node_type: :employee
  connection node_type: :genre
  connection node_type: :invoice
  connection node_type: :playlist
  connection node_type: :track

  query do
    node field do
      resolve(fn
        %{type: :album,    id: id}, resolution -> Album.resolve_node(id, resolution)
        %{type: :artist,   id: id}, resolution -> Artist.resolve_node(id, resolution)
        %{type: :customer, id: id}, resolution -> Customer.resolve_node(id, resolution)
        %{type: :employee, id: id}, resolution -> Employee.resolve_node(id, resolution)
        %{type: :genre,    id: id}, resolution -> Genre.resolve_node(id, resolution)
        %{type: :invoice,  id: id}, resolution -> Invoice.resolve_node(id, resolution)
        %{type: :playlist, id: id}, resolution -> Playlist.resolve_node(id, resolution)
        %{type: :track,    id: id}, resolution -> Track.resolve_node(id, resolution)
      end)
    end

    @desc "Paginate artists"
    connection field :artists, node_type: :artist do
      arg :by, :artist_sort_order, default_value: :artist_id
      arg :filter, :artist_filter, default_value: %{}
      resolve Artist.resolve_connection()
    end

    @desc "Paginate albums"
    connection field :albums, node_type: :album do
      arg :by, :album_sort_order, default_value: :album_id
      arg :filter, :album_filter, default_value: %{}
      resolve Album.resolve_connection()
    end

    @desc "Paginate customers"
    connection field :customers, node_type: :customer do
      arg :by, :customer_sort_order, default_value: :customer_id
      arg :filter, :customer_filter, default_value: %{}

      middleware Scope, read: :customer
      resolve Customer.resolve_connection()
    end

    @desc "Paginate employees"
    connection field :employees, node_type: :employee do
      arg :by, :employee_sort_order, default_value: :employee_id
      arg :filter, :employee_filter, default_value: %{}

      middleware ParseIDs, filter: [reports_to: :employee]
      middleware Scope, read: :employee
      resolve Employee.resolve_connection()
    end

    @desc "Paginate genres"
    connection field :genres, node_type: :genre do
      arg :by, :genre_sort_order, default_value: :genre_id
      arg :filter, :genre_filter, default_value: %{}
      resolve Genre.resolve_connection()
    end

    @desc "Paginate invoices"
    connection field :invoices, node_type: :invoice do
      arg :by, :invoice_sort_order, default_value: :invoice_id
      arg :filter, :invoice_filter, default_value: %{}

      middleware Scope, read: :invoice
      resolve Invoice.resolve_connection()
    end

    @desc "Paginate playlists"
    connection field :playlists, node_type: :playlist do
      arg :by, :playlist_sort_order, default_value: :playlist_id
      arg :filter, :playlist_filter, default_value: %{}
      resolve Playlist.resolve_connection()
    end
  end
end
