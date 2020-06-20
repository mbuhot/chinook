defmodule ChinookWeb.Schema.Customer do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias ChinookWeb.Relay

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
    field :support_rep, :employee, resolve: dataloader(Chinook.Employee.Loader)
  end
end
