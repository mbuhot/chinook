defmodule Chinook.User do
  def authenticate(email, _password) do
    found =
      Chinook.Repo.get_by(Chinook.Employee, email: email) ||
      Chinook.Repo.get_by(Chinook.Customer, email: email)

    case found do
      nil -> :error
      _ -> {:ok, found}
    end
  end
end
