defmodule Chinook.Invoice do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Customer

  @type t :: %__MODULE__{}

  @primary_key {:invoice_id, :integer, source: :InvoiceId}

  schema "Invoice" do
    field :invoice_date, :naive_datetime, source: :InvoiceDate
    field :billing_address, :string, source: :BillingAddress
    field :billing_city, :string, source: :BillingCity
    field :billing_state, :string, source: :BillingState
    field :billing_country, :string, source: :BillingCountry
    field :billing_postal_code, :string, source: :BillingPostalCode
    field :total, :decimal, source: :Total
    field :row_count, :integer, virtual: true

    belongs_to :customer, Customer, source: :CustomerId, references: :customer_id
    has_many :line_items, Invoice.Line, foreign_key: :invoice_id, references: :invoice_id
    has_many :tracks, through: [:line_items, :track]
  end

  defmodule Line do
    use Ecto.Schema
    alias Chinook.Track

    @type t :: %__MODULE__{}

    @primary_key {:invoice_line_id, :integer, source: :InvoiceLineId}

    schema "InvoiceLine" do
      field :unit_price, :decimal, source: :UnitPrice
      field :quantity, :integer, source: :Quantity
      belongs_to :invoice, Invoice, source: :InvoiceId, references: :invoice_id
      belongs_to :track, Track, source: :TrackId, references: :track_id
    end
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.QueryHelpers

    alias Chinook.Employee
    alias Chinook.Repo

    @spec by_id(integer, (Ecto.Queryable.t() -> Ecto.Queryable.t())) :: Chinook.Invoice.t()
    def by_id(id, scope) do
      %{scope: scope}
      |> query()
      |> where([i], i.invoice_id == ^id)
      |> Repo.one()
    end

    @spec page(args :: PagingOptions.t()) :: [Invoice.t()]
    def page(args) do
      args
      |> query()
      |> Repo.all()
    end

    @spec query(PagingOptions.t()) :: Ecto.Query.t()
    def query(args) do
      args = Map.put_new(args, :by, :invoice_id)

      Invoice
      |> from(as: :invoice)
      |> paginate(Invoice, :invoice, args)
      |> filter(args[:filter])
      |> scope(args[:scope])
    end

    def filter(queryable, nil), do: queryable

    def filter(queryable, filters) do
      Enum.reduce(filters, queryable, fn
        {:invoice_date, date_filter}, queryable ->
          filter_datetime(queryable, :invoice_date, date_filter)

        {:total, total_filter}, queryable ->
          filter_number(queryable, :total, total_filter)
      end)
    end

    def scope(queryable, :all) do
      queryable
    end

    def scope(queryable, customer_id: customer_id) do
      queryable
      |> where([invoice: i], i.customer_id == ^customer_id)
    end

    def scope(queryable, support_rep_id: support_rep_id) do
      queryable
      |> ensure_customer_binding()
      |> Chinook.Customer.Loader.scope(support_rep_id: support_rep_id)
    end

    defp ensure_customer_binding(queryable) do
      if has_named_binding?(queryable, :customer) do
        queryable
      else
        queryable |> join(:inner, [invoice: i], c in assoc(i, :customer), as: :customer)
      end
    end
  end

  defmodule Auth do
    alias Chinook.{Employee, Customer}

    @type scope :: :all | [support_rep_id: integer()] | [customer_id: integer()]
    @type user :: Employee.t() | Customer.t()
    @type action :: :read
    @type resource :: :invoice

    @spec can?(user, action, resource) :: {:ok, scope} | {:error, atom}
    def can?(%Employee{title: "General Manager"}, :read, :invoice) do
      {:ok, :all}
    end

    def can?(%Employee{title: "Sales Manager"}, :read, :invoice) do
      {:ok, :all}
    end

    def can?(%Employee{title: "Sales Support Agent"} = e, :read, :invoice) do
      {:ok, [support_rep_id: e.employee_id]}
    end

    def can?(%Employee{}, :read, :invoice) do
      {:error, :not_authorized}
    end

    def can?(%Customer{} = c, :read, :invoice) do
      {:ok, [customer_id: c.customer_id]}
    end
  end
end
