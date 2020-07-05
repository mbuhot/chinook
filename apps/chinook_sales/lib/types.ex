defmodule Chinook.Sales.Types do
  defmacro __using__(_opts) do
    quote do
      import_types Chinook.Sales.Customer.Schema
      import_types Chinook.Sales.Employee.Schema
      import_types Chinook.Sales.Invoice.Schema
      import_types Chinook.Sales.Connections
    end
  end
end
