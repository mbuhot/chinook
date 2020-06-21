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

  def context(ctx) do
    loader = Chinook.Loader.data()
    Map.put(ctx, :loader, loader)
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
        %{type: :album, id: id}, _resolution ->
          {:ok, Chinook.Album.Loader.by_id(id)}

        %{type: :artist, id: id}, _resolution ->
          {:ok, Chinook.Artist.Loader.by_id(id)}

        %{type: :customer, id: id}, %{context: %{current_user: current_user}} ->
          with {:ok, scope} <- Chinook.Customer.Auth.can?(current_user, :read, :customer) do
            {:ok, Chinook.Customer.Loader.by_id(id, scope)}
          end

        %{type: :customer}, _resolution ->
          {:error, :not_authorized}

        %{type: :employee, id: id}, _resolution ->
          {:ok, Chinook.Employee.Loader.by_id(id)}

        %{type: :genre, id: id}, _resolution ->
          {:ok, Chinook.Genre.Loader.by_id(id)}

        %{type: :invoice, id: id}, %{context: %{current_user: current_user}} ->
          with {:ok, scope} <- Chinook.Invoice.Auth.can?(current_user, :read, :invoice) do
            {:ok, Chinook.Invoice.Loader.by_id(id, scope)}
          end

        %{type: :playlist, id: id}, _resolution ->
          {:ok, Chinook.Playlist.Loader.by_id(id)}

        %{type: :track, id: id}, _resolution ->
          {:ok, Chinook.Track.Loader.by_id(id)}
      end)
    end

    @desc "Paginate artists"
    connection field :artists, node_type: :artist do
      arg :by, :artist_sort_order, default_value: :artist_id
      arg :filter, :artist_filter, default_value: %{}

      resolve fn args, _resolution ->
        Relay.resolve_connection(Chinook.Artist.Loader, :page, args)
      end
    end

    @desc "Paginate customers"
    connection field :customers, node_type: :customer do
      arg :by, :customer_sort_order, default_value: :customer_id
      arg :filter, :customer_filter, default_value: %{}

      resolve fn
        args, %{context: %{current_user: current_user}} ->
          with {:ok, scope} <- Chinook.Customer.Auth.can?(current_user, :read, :customer) do
            args = Map.put(args, :scope, scope)
            Relay.resolve_connection(Chinook.Customer.Loader, :page, args)
          end

        _args, _context ->
          {:error, :not_authorized}
      end
    end

    @desc "Paginate employees"
    connection field :employees, node_type: :employee do
      arg :by, :employee_sort_order, default_value: :employee_id
      arg :filter, :employee_filter, default_value: %{}

      resolve fn args, _resolution ->
        args = Employee.decode_filter(args)
        Relay.resolve_connection(Chinook.Employee.Loader, :page, args)
      end
    end

    @desc "Paginate genres"
    connection field :genres, node_type: :genre do
      arg :by, :genre_sort_order, default_value: :genre_id
      arg :filter, :genre_filter, default_value: %{}

      resolve fn args, _resolution ->
        Relay.resolve_connection(Chinook.Genre.Loader, :page, args)
      end
    end

    @desc "Paginate invoices"
    connection field :invoices, node_type: :invoice do
      arg :by, :invoice_sort_order, default_value: :invoice_id
      arg :filter, :invoice_filter, default_value: %{}

      resolve fn
        args, %{context: %{current_user: current_user}} ->
          with {:ok, scope} <- Chinook.Invoice.Auth.can?(current_user, :read, :invoice) do
            args = Map.put(args, :scope, scope)
            Relay.resolve_connection(Chinook.Invoice.Loader, :page, args)
          end
        _args, _resolution ->
          {:error, :not_authorized}
      end
    end

    @desc "Paginate playlists"
    connection field :playlists, node_type: :playlist do
      arg :by, :playlist_sort_order, default_value: :playlist_id
      arg :filter, :playlist_filter, default_value: %{}

      resolve fn args, _resolution ->
        Relay.resolve_connection(Chinook.Playlist.Loader, :page, args)
      end
    end
  end
end
