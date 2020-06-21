defmodule Chinook.Employee do
  use Ecto.Schema
  alias __MODULE__

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

    belongs_to :reports_to, Employee, source: :ReportsTo, references: :employee_id
    has_many :reports, Employee, foreign_key: :reports_to_id, references: :employee_id
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers

    alias Chinook.Repo

    @spec new() :: Dataloader.Ecto.t()
    def new() do
      Dataloader.Ecto.new(
        Chinook.Repo,
        query: fn Employee, args -> query(args) end
      )
    end

    @spec by_id(integer) :: Employee.t()
    def by_id(id) do
      Repo.get(Employee, id)
    end

    def by_email(email) do
      Repo.get_by(Employee, email: email)
    end

    @spec page(args :: PagingOptions.t()) :: [Employee.t()]
    def page(args) do
      args
      |> query()
      |> Repo.all()
    end

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :employee_id)

      from(Employee, as: :employee)
      |> paginate(:employee, args)
      |> filter(args[:filter])
    end

    def filter(queryable, nil), do: queryable
    def filter(queryable, filters) do
      Enum.reduce(filters, queryable, fn
        {:reports_to, manager_id}, queryable -> queryable |> where(^[reports_to_id: manager_id])
        {:last_name, last_name_filter}, queryable -> filter_string(queryable, :last_name, last_name_filter)
        {:first_name, first_name_filter}, queryable -> filter_string(queryable, :first_name, first_name_filter)
        {:title, title_filter}, queryable -> filter_string(queryable, :title, title_filter)
        {:birth_date, birth_date_filter}, queryable -> filter_datetime(queryable, :birth_date, birth_date_filter)
        {:hire_date, hire_date_filter}, queryable -> filter_datetime(queryable, :hire_date, hire_date_filter)
        {:address, address_filter}, queryable -> filter_string(queryable, :address, address_filter)
        {:city, city_filter}, queryable -> filter_string(queryable, :city, city_filter)
        {:state, state_filter}, queryable -> filter_string(queryable, :state, state_filter)
        {:country, country_filter}, queryable -> filter_string(queryable, :country, country_filter)
        {:postal_code, postal_code_filter}, queryable -> filter_string(queryable, :postal_code, postal_code_filter)
        {:phone, phone_filter}, queryable -> filter_string(queryable, :phone, phone_filter)
        {:fax, fax_filter}, queryable -> filter_string(queryable, :fax, fax_filter)
        {:email, email_filter}, queryable -> filter_string(queryable, :email, email_filter)
      end)
    end
  end
end
