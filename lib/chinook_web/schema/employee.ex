defmodule ChinookWeb.Schema.Employee do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias ChinookWeb.Relay

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

    field :reports_to, :employee, resolve: dataloader(Chinook.Employee.Loader)

    connection field :reports, node_type: :employee do
      arg :by, :employee_sort_order, default_value: :employee_id
      arg :filter, :employee_filter, default_value: %{}

      resolve fn employee, args, %{context: %{loader: loader}} ->
        args = decode_filter(args)
        Relay.resolve_connection_dataloader(
          loader,
          Chinook.Employee.Loader,
          Chinook.Employee,
          args,
          reports_to_id: employee.employee_id
        )
      end
    end

    connection field :customers, node_type: :customer do
      arg :by, :customer_sort_order, default_value: :customer_id
      arg :filter, :customer_filter, default_value: %{}

      resolve fn employee, args, %{context: %{loader: loader}} ->
        Relay.resolve_connection_dataloader(
          loader,
          Chinook.Customer.Loader,
          Chinook.Customer,
          args,
          support_rep_id: employee.employee_id
        )
      end
    end
  end

  def decode_filter(args = %{filter: %{reports_to: report_to_id}}) do
    {:ok, %{id: decoded, type: :employee}} =
      Absinthe.Relay.Node.from_global_id(report_to_id, ChinookWeb.Schema)

    put_in(args.filter.reports_to, decoded)
  end
  def decode_filter(args), do: args
end
