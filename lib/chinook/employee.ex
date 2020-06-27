defmodule Chinook.Employee do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Customer

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
    import Chinook.QueryHelpers

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
    alias Chinook.{Customer, Employee}

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
end
