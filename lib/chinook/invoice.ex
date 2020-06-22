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
    belongs_to :customer, Customer, source: :CustomerId, references: :customer_id
    has_many :line_items, Invoice.Line, foreign_key: :invoice_id, references: :invoice_id
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

    @spec new() :: Dataloader.Ecto.t()
    def new() do
      Dataloader.Ecto.new(
        Repo,
        query: fn
          Invoice, args -> query(args)
          Invoice.Line, args when map_size(args) == 0 -> Invoice.Line
        end
      )
    end

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

      from(Invoice, as: :invoice)
      |> paginate(:invoice, args)
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

    def scope(queryable, nil), do: queryable |> where(false)
    def scope(queryable, f) when is_function(f), do: f.(queryable)
  end

  defmodule Auth do
    import Ecto.Query
    alias Chinook.Employee

    def can?(%Employee{title: "General Manager"}, :read, :invoice), do: {:ok, & &1}
    def can?(%Employee{title: "Sales Manager"}, :read, :invoice), do: {:ok, & &1}

    def can?(%Employee{title: "Sales Support Agent"} = e, :read, :invoice) do
      {:ok, &scope_to_support_rep(&1, e)}
    end

    def can?(%Employee{}, :read, :invoice), do: {:error, :not_authorized}

    def can?(%Customer{} = c, :read, :invoice) do
      {:ok, &scope_to_customer(&1, c)}
    end

    def scope_to_customer(queryable, %Customer{customer_id: customer_id}) do
      queryable
      |> where([invoice: i], i.customer_id == ^customer_id)
    end

    def scope_to_support_rep(queryable, %Employee{} = e) do
      queryable
      |> ensure_customer_binding()
      |> Customer.Auth.scope_to_support_rep(e)
    end

    defp ensure_customer_binding(queryable) do
      if has_named_binding?(queryable, :customer) do
        queryable
      else
        queryable |> join(:inner, [invoice: i], c in assoc(i, :customer), as: :customer)
      end
    end
  end
end
