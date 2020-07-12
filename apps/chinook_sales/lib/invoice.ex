defmodule Chinook.Sales.Invoice do
  use Ecto.Schema
  alias __MODULE__
  alias Chinook.Sales.Customer

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

    @type t :: %__MODULE__{}

    @primary_key {:invoice_line_id, :integer, source: :InvoiceLineId}

    schema "InvoiceLine" do
      field :unit_price, :decimal, source: :UnitPrice
      field :quantity, :integer, source: :Quantity
      field :track_id, :integer, source: :TrackId
      belongs_to :invoice, Invoice, source: :InvoiceId, references: :invoice_id
    end
  end

  defmodule Track do
    use Ecto.Schema
    @type t :: %__MODULE__{}
    @primary_key {:track_id, :integer, source: :TrackId}

    schema "Track" do
      field :album_id, :integer, source: :AlbumId
      field :genre_id, :integer, source: "AlbumId"
    end
  end

  defmodule Loader do
    import Ecto.Query
    import Chinook.Util.QueryHelpers

    alias Chinook.Sales.Employee

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
      |> Chinook.Sales.Customer.Loader.scope(support_rep_id: support_rep_id)
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
    alias Chinook.Sales.{Employee, Customer}

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

  defmodule Schema do
    use Absinthe.Schema.Notation
    use Absinthe.Relay.Schema.Notation, :modern

    import Absinthe.Resolution.Helpers, only: [dataloader: 1]

    alias Chinook.Util.Relay
    alias Chinook.Util.Scope

    @desc "Invoice sort order"
    enum :invoice_sort_order do
      value :id, as: :invoice_id
      value :invoice_date, as: :invoice_date
      value :total, as: :total
    end

    @desc "Invoice filter"
    input_object :invoice_filter do
      field :invoice_date, :datetime_filter
      field :total, :decimal_filter
    end

    node object(:invoice, id_fetcher: &Relay.id/2) do
      field :invoice_date, :naive_datetime
      field :billing_address, :string
      field :billing_city, :string
      field :billing_state, :string
      field :billing_country, :string
      field :billing_postal_code, :string
      field :total, :decimal

      field :customer, :customer do
        middleware Scope, read: :customer
        resolve dataloader(Chinook.Sales.Loader)
      end

      # line_items is not a connection here, just a list that can be resolved along with the
      # invoice if needed by the client.
      field :line_items, list_of(:invoice_line), resolve: dataloader(Chinook.Sales.Loader)
    end

    # Using `node object` here for convenience of letting Relay generate the opaque ID
    # invoice_line is not a true node type, it can't be resolved using the Schema.node field.
    node object(:invoice_line, id_fetcher: &Relay.id/2) do
      field :unit_price, :decimal
      field :quantity, :integer

      field :track, :track do
        resolve fn invoice_line, _args, res ->
          Relay.node_dataloader(
            res.context.loader,
            Chinook.Catalog.Loader,
            Chinook.Catalog.Track,
            invoice_line.track_id
          )
        end
      end

      field :invoice, :invoice do
        middleware Scope, read: :invoice
        resolve dataloader(Chinook.Sales.Loader)
      end
    end
  end
end
