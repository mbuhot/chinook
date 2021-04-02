defmodule ChinookWeb.Schema.Invoice do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias ChinookWeb.Relay
  alias ChinookWeb.Scope

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
      resolve Relay.node_dataloader(Chinook.Loader)
    end

    # line_items is not a connection here, just a list that can be resolved along with the
    # invoice if needed by the client.
    field :line_items, list_of(:invoice_line), resolve: dataloader(Chinook.Loader)
  end

  # Using `node object` here for convenience of letting Relay generate the opaque ID
  # invoice_line is not a true node type, it can't be resolved using the Schema.node field.
  node object(:invoice_line, id_fetcher: &Relay.id/2) do
    field :unit_price, :decimal
    field :quantity, :integer
    field :track, :track, resolve: Relay.node_dataloader(Chinook.Loader)

    field :invoice, :invoice do
      middleware Scope, read: :invoice
      resolve Relay.node_dataloader(Chinook.Loader)
    end
  end

  def resolve_node(id, resolution = %{context: %{current_user: current_user}}) do
    with {:ok, scope} <- Chinook.Invoice.Auth.can?(current_user, :read, :invoice) do
      Relay.node_dataloader(Chinook.Loader, {Chinook.Invoice, %{scope: scope}}, id, resolution)
    end
  end

  def resolve_connection do
    Relay.connection_from_query(&Chinook.Invoice.Loader.query/1)
  end
end
