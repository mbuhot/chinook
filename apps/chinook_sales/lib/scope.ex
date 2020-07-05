defmodule Chinook.Util.Scope do
  @behaviour Absinthe.Middleware

  # TODO: Move these into Billing and Company apps
  def call(res, read: :invoice), do: scope_with(res, Chinook.Sales.Invoice.Auth, :read, :invoice)

  def call(res, read: :employee),
    do: scope_with(res, Chinook.Sales.Employee.Auth, :read, :employee)

  def call(res, read: :customer),
    do: scope_with(res, Chinook.Sales.Customer.Auth, :read, :customer)

  defp scope_with(res, mod, action, resource) do
    with {:ok, current_user} <- Map.fetch(res.context, :current_user),
         {:ok, scope} <- mod.can?(current_user, action, resource) do
      put_scope(res, scope)
    else
      :error -> Absinthe.Resolution.put_result(res, {:error, :not_authorized})
      {:error, err} -> Absinthe.Resolution.put_result(res, {:error, err})
    end
  end

  defp put_scope(resolution = %{context: context, arguments: arguments}, scope) do
    %{
      resolution
      | context: Map.put(context, :scope, scope),
        arguments: Map.put(arguments, :scope, scope)
    }
  end
end
