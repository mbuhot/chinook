defmodule Chinook.Sales.Graph do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias Chinook.Util.Relay
  alias Chinook.Util.Scope

  defmacro __using__(_opts) do
    quote do
      import_types Chinook.Sales.Customer.Schema
      import_types Chinook.Sales.Employee.Schema
      import_types Chinook.Sales.Invoice.Schema
      import_types Chinook.Sales.Graph
    end
  end

  connection(node_type: :customer)
  connection(node_type: :employee)
  connection(node_type: :invoice)

  object :sales_connections do
    @desc "Paginate employees"
    connection field :employees, node_type: :employee do
      arg :by, :employee_sort_order, default_value: :employee_id
      arg :filter, :employee_filter, default_value: %{}

      middleware &Chinook.Sales.Employee.Schema.decode_filter/2
      middleware Scope, read: :employee
      resolve Relay.connection_from_query(&Chinook.Sales.Employee.Loader.query/1)
    end

    @desc "Paginate customers"
    connection field :customers, node_type: :customer do
      arg :by, :customer_sort_order, default_value: :customer_id
      arg :filter, :customer_filter, default_value: %{}

      middleware Scope, read: :customer
      resolve Relay.connection_from_query(&Chinook.Sales.Customer.Loader.query/1)
    end

    @desc "Paginate invoices"
    connection field :invoices, node_type: :invoice do
      arg :by, :invoice_sort_order, default_value: :invoice_id
      arg :filter, :invoice_filter, default_value: %{}

      middleware Scope, read: :invoice
      resolve Relay.connection_from_query(&Chinook.Sales.Invoice.Loader.query/1)
    end
  end

  def resolve_type(%Chinook.Sales.Customer{}, _), do: :customer
  def resolve_type(%Chinook.Sales.Employee{}, _), do: :employee
  def resolve_type(%Chinook.Sales.Invoice{}, _), do: :invoice
  def resolve_type(_, _), do: nil

  def resolve_node(%{type: :customer, id: id}, %{
        context: %{current_user: current_user, loader: loader}
      }) do
    with {:ok, scope} <- Chinook.Sales.Customer.Auth.can?(current_user, :read, :customer) do
      Relay.node_dataloader(
        loader,
        Chinook.Sales.Loader,
        {Chinook.Sales.Customer, %{scope: scope}},
        id
      )
    end
  end

  def resolve_node(%{type: :employee, id: id}, %{
        context: %{current_user: current_user, loader: loader}
      }) do
    with {:ok, scope} <- Chinook.Sales.Employee.Auth.can?(current_user, :read, :employee) do
      Relay.node_dataloader(
        loader,
        Chinook.Sales.Loader,
        {Chinook.Sales.Employee, %{scope: scope}},
        id
      )
    end
  end

  def resolve_node(%{type: :invoice, id: id}, %{
        context: %{current_user: current_user, loader: loader}
      }) do
    with {:ok, scope} <- Chinook.Sales.Invoice.Auth.can?(current_user, :read, :invoice) do
      Relay.node_dataloader(
        loader,
        Chinook.Sales.Loader,
        {Chinook.Sales.Invoice, %{scope: scope}},
        id
      )
    end
  end

  def resolve_node(_, _), do: nil
end
