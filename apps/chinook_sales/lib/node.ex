defmodule Chinook.Sales.Node do
  alias Chinook.Util.Relay

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
