defmodule ChinookWeb.Schema.Customer do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias ChinookWeb.Relay
  alias ChinookWeb.Scope

  @desc "Customer sort order"
  enum :customer_sort_order do
    value :id, as: :customer_id
    value :last_name, as: :last_name
    value :email, as: :email
  end

  @desc "Customer filter"
  input_object :customer_filter do
    field :first_name, :string_filter
    field :last_name, :string_filter
    field :company, :string_filter
    field :address, :string_filter
    field :city, :string_filter
    field :state, :string_filter
    field :country, :string_filter
    field :postal_code, :string_filter
    field :phone, :string_filter
    field :fax, :string_filter
    field :email, :string_filter
  end

  node object(:customer, id_fetcher: &Relay.id/2) do
    field :first_name, :string
    field :last_name, :string
    field :company, :string
    field :address, :string
    field :city, :string
    field :state, :string
    field :country, :string
    field :postal_code, :string
    field :phone, :string
    field :fax, :string
    field :email, :string

    field :support_rep, :employee do
      middleware Scope, read: :employee
      resolve dataloader(Chinook.Loader)
    end

    connection field :invoices, node_type: :invoice do
      arg :by, :invoice_sort_order, default_value: :invoice_id
      arg :filter, :invoice_filter, default_value: %{}
      middleware Scope, read: :invoice
      resolve Relay.connection_dataloader(Chinook.Loader)
    end

    connection field :tracks, node_type: :track do
      arg :by, :track_sort_order, default_value: :track_id
      arg :filter, :track_filter, default_value: %{}
      resolve Relay.connection_dataloader(Chinook.Loader)
    end
  end
end
