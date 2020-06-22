defmodule ChinookWeb.Schema.Employee do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias ChinookWeb.Relay
  alias ChinookWeb.Scope

  @desc "Employee sort order"
  enum :employee_sort_order do
    value :id, as: :employee_id
    value :last_name, as: :last_name
    value :hired_date, as: :hired_date
  end

  @desc "Employee filter"
  input_object :employee_filter do
    field :reports_to, :id
    field :last_name, :string_filter
    field :first_name, :string_filter
    field :title, :string_filter
    field :birth_date, :datetime_filter
    field :hire_date, :datetime_filter
    field :address, :string_filter
    field :city, :string_filter
    field :state, :string_filter
    field :country, :string_filter
    field :postal_code, :string_filter
    field :phone, :string_filter
    field :fax, :string_filter
    field :email, :string_filter
  end

  node object(:employee, id_fetcher: &Relay.id/2) do
    field :last_name, :string
    field :first_name, :string
    field :title, :string
    field :birth_date, :datetime
    field :hire_date, :datetime
    field :address, :string
    field :city, :string
    field :state, :string
    field :country, :string
    field :postal_code, :string
    field :phone, :string
    field :fax, :string
    field :email, :string

    field :reports_to, :employee do
      middleware Scope, [read: :employee]
      resolve dataloader(Chinook.Employee.Loader)
    end

    connection field :reports, node_type: :employee do
      arg :by, :employee_sort_order, default_value: :employee_id
      arg :filter, :employee_filter, default_value: %{}

      middleware :decode_filter
      middleware Scope, [read: :employee]
      resolve Relay.connection_dataloader(Chinook.Employee.Loader)
    end

    connection field :customers, node_type: :customer do
      arg :by, :customer_sort_order, default_value: :customer_id
      arg :filter, :customer_filter, default_value: %{}

      middleware Scope, [read: :customer]
      resolve Relay.connection_dataloader(Chinook.Customer.Loader)
    end
  end

  def decode_filter(res = %{arguments: %{filter: %{reports_to: report_to_id}}}, _opts) do
    {:ok, %{id: decoded, type: :employee}} =
      Absinthe.Relay.Node.from_global_id(report_to_id, ChinookWeb.Schema)

    put_in(res.arguments.filter.reports_to, decoded)
  end

  def decode_filter(res, _opts), do: res
end
