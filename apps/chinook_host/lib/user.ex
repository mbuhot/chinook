defmodule ChinookHost.User do
  def authenticate(email, _password) do
    found =
      ChinookRepo.get_by(Chinook.Sales.Employee, email: email) ||
        ChinookRepo.get_by(Chinook.Sales.Customer, email: email)

    case found do
      nil -> :error
      _ -> {:ok, found}
    end
  end
end
