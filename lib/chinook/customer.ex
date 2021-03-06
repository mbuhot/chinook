defmodule Chinook.Customer do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Employee
  alias Chinook.Invoice

  @type t :: %__MODULE__{}

  @primary_key {:customer_id, :integer, source: :CustomerId}

  schema "Customer" do
    field :first_name, :string, source: :FirstName
    field :last_name, :string, source: :LastName
    field :company, :string, source: :Company
    field :address, :string, source: :Address
    field :city, :string, source: :City
    field :state, :string, source: :State
    field :country, :string, source: :Country
    field :postal_code, :string, source: :PostalCode
    field :phone, :string, source: :Phone
    field :fax, :string, source: :Fax
    field :email, :string, source: :Email
    field :row_count, :integer, virtual: true

    belongs_to :support_rep, Employee, source: :SupportRepId, references: :employee_id
    has_many :invoices, Invoice, foreign_key: :customer_id, references: :customer_id
    has_many :tracks, through: [:invoices, :tracks]
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :customer_id)

      Customer
      |> from(as: :customer)
      |> select_fields(Customer, :customer, args[:fields])
      |> paginate(Customer, :customer, args)
      |> filter(args[:filter])
      |> scope(args[:scope])
    end

    def filter(queryable, nil), do: queryable

    def filter(queryable, filters) do
      Enum.reduce(filters, queryable, fn
        {:last_name, last_name_filter}, queryable ->
          filter_string(queryable, :last_name, last_name_filter)

        {:first_name, first_name_filter}, queryable ->
          filter_string(queryable, :first_name, first_name_filter)

        {:company, company_filter}, queryable ->
          filter_string(queryable, :company, company_filter)

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

        {:support_rep, support_rep_id}, queryable ->
          queryable |> where(^[support_rep_id: support_rep_id])
      end)
    end

    @spec scope(Ecto.Queryable.t(), Customer.Auth.scope()) :: Ecto.Queryable.t()
    def scope(queryable, :all), do: queryable

    def scope(queryable, customer_id: customer_id) do
      queryable
      |> where([customer: c], c.customer_id == ^customer_id)
    end

    def scope(queryable, support_rep_id: employee_id) do
      queryable
      |> where([customer: c], c.support_rep_id == ^employee_id)
    end

    def scope(queryable, _), do: queryable |> where(false)
  end

  defmodule Auth do
    @type scope :: :all | [support_rep_id: integer()] | [customer_id: integer()]
    @type user :: Employee.t() | Customer.t()
    @type action :: :read
    @type resource :: :customer

    @spec can?(user, action, resource) :: {:ok, scope} | {:error, atom}
    def can?(%Employee{title: "General Manager"}, :read, :customer) do
      {:ok, :all}
    end

    def can?(%Employee{title: "Sales Manager"}, :read, :customer) do
      {:ok, :all}
    end

    def can?(%Employee{title: "Sales Support Agent"} = e, :read, :customer) do
      {:ok, [support_rep_id: e.employee_id]}
    end

    def can?(%Employee{}, :read, :customer) do
      {:error, :not_authorized}
    end

    def can?(%Customer{} = c, :read, :customer) do
      {:ok, [customer_id: c.customer_id]}
    end
  end
end
