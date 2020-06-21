defmodule ChinookWeb.GraphQLContext do
  @behaviour Plug

  import Plug.Conn
  import Ecto.Query, only: [where: 2]

  alias Chinook.Customer
  alias Chinook.Employee

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def build_context(conn) do
    with {user, _pass} <- Plug.BasicAuth.parse_basic_auth(conn) do
      current_user =
        Employee.Loader.by_email(user) ||
        Customer.Loader.by_email(user)

      %{current_user: current_user}
    else
      :error -> %{}
    end
  end
end
