defmodule Chinook.Sales.Connections do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias Chinook.Util.Relay
  alias Chinook.Util.Scope

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
end
