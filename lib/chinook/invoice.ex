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

    @spec by_id(integer) :: Chinook.Invoice.t()
    def by_id(id) do
      Repo.get(Invoice, id)
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
    end

    def filter(queryable, nil), do: queryable
    def filter(queryable, filters) do
      Enum.reduce(filters, queryable, fn
        {:invoice_date, date_filter}, queryable -> filter_datetime(queryable, :invoice_date, date_filter)
        {:total, total_filter}, queryable -> filter_number(queryable, :total, total_filter)
      end)
    end
  end
end
