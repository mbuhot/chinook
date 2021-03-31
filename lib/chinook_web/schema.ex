defmodule ChinookWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias ChinookWeb.Relay
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

  connection(node_type: :album)
  connection(node_type: :artist)
  connection(node_type: :customer)
  connection(node_type: :employee)
  connection(node_type: :genre)
  connection(node_type: :invoice)
  connection(node_type: :playlist)
  connection(node_type: :track)

  query do
    node field do
      resolve(fn
        %{type: :album, id: id}, resolution ->
          Relay.node_dataloader(Chinook.Loader, Chinook.Album, id, resolution)

        %{type: :artist, id: id}, resolution ->
          Relay.node_dataloader(Chinook.Loader, Chinook.Artist, id, resolution)

        %{type: :customer, id: id}, resolution = %{context: %{current_user: current_user}} ->
          with {:ok, scope} <- Chinook.Customer.Auth.can?(current_user, :read, :customer) do
            Relay.node_dataloader(Chinook.Loader, {Chinook.Customer, %{scope: scope}}, id, resolution)
          end

        %{type: :employee, id: id}, resolution = %{context: %{current_user: current_user}} ->
          with {:ok, scope} <- Chinook.Employee.Auth.can?(current_user, :read, :employee) do
            Relay.node_dataloader(Chinook.Loader, {Chinook.Employee, %{scope: scope}}, id, resolution)
          end

        %{type: :genre, id: id}, resolution ->
          Relay.node_dataloader(Chinook.Loader, Chinook.Genre, id, resolution)

        %{type: :invoice, id: id}, resolution = %{context: %{current_user: current_user}} ->
          with {:ok, scope} <- Chinook.Invoice.Auth.can?(current_user, :read, :invoice) do
            Relay.node_dataloader(Chinook.Loader, {Chinook.Invoice, %{scope: scope}}, id, resolution)
          end

        %{type: :playlist, id: id}, resolution ->
          Relay.node_dataloader(Chinook.Loader, Chinook.Playlist, id, resolution)

        %{type: :track, id: id}, resolution ->
          Relay.node_dataloader(Chinook.Loader, Chinook.Track, id, resolution)
      end)
    end

    @desc "Paginate artists"
    connection field :artists, node_type: :artist do
      arg :by, :artist_sort_order, default_value: :artist_id
      arg :filter, :artist_filter, default_value: %{}

      resolve Relay.connection_from_query(&Chinook.Artist.Loader.query/1)
    end


    @desc "Paginate albums"
    connection field :albums, node_type: :album do
      arg :by, :album_sort_order, default_value: :album_id
      arg :filter, :album_filter, default_value: %{}

      resolve Relay.connection_from_query(&Chinook.Album.Loader.query/1)
    end

    @desc "Paginate customers"
    connection field :customers, node_type: :customer do
      arg :by, :customer_sort_order, default_value: :customer_id
      arg :filter, :customer_filter, default_value: %{}

      middleware Scope, read: :customer
      resolve Relay.connection_from_query(&Chinook.Customer.Loader.query/1)
    end

    @desc "Paginate employees"
    connection field :employees, node_type: :employee do
      arg :by, :employee_sort_order, default_value: :employee_id
      arg :filter, :employee_filter, default_value: %{}

      middleware &Employee.decode_filter/2
      middleware Scope, read: :employee
      resolve Relay.connection_from_query(&Chinook.Employee.Loader.query/1)
    end

    @desc "Paginate genres"
    connection field :genres, node_type: :genre do
      arg :by, :genre_sort_order, default_value: :genre_id
      arg :filter, :genre_filter, default_value: %{}

      resolve Relay.connection_from_query(&Chinook.Genre.Loader.query/1)
    end

    @desc "Paginate invoices"
    connection field :invoices, node_type: :invoice do
      arg :by, :invoice_sort_order, default_value: :invoice_id
      arg :filter, :invoice_filter, default_value: %{}

      middleware Scope, read: :invoice
      resolve Relay.connection_from_query(&Chinook.Invoice.Loader.query/1)
    end

    @desc "Paginate playlists"
    connection field :playlists, node_type: :playlist do
      arg :by, :playlist_sort_order, default_value: :playlist_id
      arg :filter, :playlist_filter, default_value: %{}

      resolve Relay.connection_from_query(&Chinook.Playlist.Loader.query/1)
    end
  end
end
