defmodule Chinook.Sales.Employee do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Sales.Customer

  @type t :: %__MODULE__{}

  @primary_key {:employee_id, :integer, source: :EmployeeId}

  schema "Employee" do
    field :last_name, :string, source: :LastName
    field :first_name, :string, source: :FirstName
    field :title, :string, source: :Title
    field :birth_date, :utc_datetime, source: :BirthDate
    field :hire_date, :utc_datetime, source: :HireDate
    field :address, :string, source: :Address
    field :city, :string, source: :City
    field :state, :string, source: :State
    field :country, :string, source: :Country
    field :postal_code, :string, source: :PostalCode
    field :phone, :string, source: :Phone
    field :fax, :string, source: :Fax
    field :email, :string, source: :Email
    field :row_count, :integer, virtual: true

    belongs_to :reports_to, Employee, source: :ReportsTo, references: :employee_id
    has_many :reports, Employee, foreign_key: :reports_to_id, references: :employee_id
    has_many :customers, Customer, foreign_key: :support_rep_id, references: :employee_id
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.Util.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :employee_id)

      Employee
      |> from(as: :employee)
      |> paginate(Employee, :employee, args)
      |> filter(args[:filter])
      |> scope(args[:scope])
    end

    def filter(queryable, nil), do: queryable

    def filter(queryable, filters) do
      Enum.reduce(filters, queryable, fn
        {:reports_to, manager_id}, queryable ->
          queryable |> where(^[reports_to_id: manager_id])

        {:last_name, last_name_filter}, queryable ->
          filter_string(queryable, :last_name, last_name_filter)

        {:first_name, first_name_filter}, queryable ->
          filter_string(queryable, :first_name, first_name_filter)

        {:title, title_filter}, queryable ->
          filter_string(queryable, :title, title_filter)

        {:birth_date, birth_date_filter}, queryable ->
          filter_datetime(queryable, :birth_date, birth_date_filter)

        {:hire_date, hire_date_filter}, queryable ->
          filter_datetime(queryable, :hire_date, hire_date_filter)

        {:address, address_filter}, queryable ->
          filter_string(queryable, :address, address_filter)

        {:city, city_filter}, queryable ->
          filter_string(queryable, :city, city_filter)

        {:state, state_filter}, queryable ->
          filter_string(queryable, :state, state_filter)

        {:country, country_filter}, queryable ->
          filter_string(queryable, :country, country_filter)

        {:postal_code, postal_code_filter}, queryable ->
          filter_string(queryable, :postal_code, postal_code_filter)

        {:phone, phone_filter}, queryable ->
          filter_string(queryable, :phone, phone_filter)

        {:fax, fax_filter}, queryable ->
          filter_string(queryable, :fax, fax_filter)

        {:email, email_filter}, queryable ->
          filter_string(queryable, :email, email_filter)
      end)
    end

    def scope(queryable, :all) do
      queryable
    end

    def scope(queryable, employee_id: employee_id, reports_to_id: reports_to_id) do
      queryable
      |> where(
        [employee: e],
        # employee can access their own records
        # manager can access employee records
        # employe can access manager records - TODO: limit this access
        e.employee_id == ^employee_id or
          e.reports_to_id == ^employee_id or
          e.employee_id == ^reports_to_id
      )
    end

    def scope(queryable, employee_id: employee_id) do
      queryable
      |> where([employee: e], e.employee_id == ^employee_id)
    end
  end

  defmodule Auth do
    alias Chinook.Sales.{Customer, Employee}

    @type scope ::
            :all
            | [employee_id: integer, reports_to_id: integer()]
            | [employee_id: integer]

    @type user :: Employee.t() | Customer.t()
    @type action :: :read
    @type resource :: :employee

    def can?(%Employee{title: "General Manager"}, :read, :employee) do
      {:ok, :all}
    end

    def can?(%Employee{} = e, :read, :employee) do
      {:ok, [employee_id: e.employee_id, reports_to_id: e.reports_to_id]}
    end

    def can?(%Customer{} = c, :read, :employee) do
      {:ok, [employee_id: c.support_rep_id]}
    end

    def can?(_, :read, :employee) do
      {:error, :not_authorized}
    end
  end

  defmodule Schema do
    use Absinthe.Schema.Notation
    use Absinthe.Relay.Schema.Notation, :modern

    import Absinthe.Resolution.Helpers, only: [dataloader: 1]

    alias Chinook.Util.Relay
    alias Chinook.Util.Scope

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
        middleware Scope, read: :employee
        resolve dataloader(Chinook.Sales.Loader)
      end

      connection field :reports, node_type: :employee do
        arg :by, :employee_sort_order, default_value: :employee_id
        arg :filter, :employee_filter, default_value: %{}

        middleware :decode_filter
        middleware Scope, read: :employee
        resolve Relay.connection_dataloader(Chinook.Sales.Loader)
      end

      connection field :customers, node_type: :customer do
        arg :by, :customer_sort_order, default_value: :customer_id
        arg :filter, :customer_filter, default_value: %{}

        middleware Scope, read: :customer
        resolve Relay.connection_dataloader(Chinook.Sales.Loader)
      end
    end

    def decode_filter(res = %{arguments: %{filter: %{reports_to: report_to_id}}}, _opts) do
      {:ok, %{id: decoded, type: :employee}} =
        Absinthe.Relay.Node.from_global_id(report_to_id, ChinookWeb.Schema)

      put_in(res.arguments.filter.reports_to, decoded)
    end

    def decode_filter(res, _opts), do: res
  end
end
