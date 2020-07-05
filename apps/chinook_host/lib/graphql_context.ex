defmodule ChinookHost.GraphQLContext do
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def build_context(conn) do
    with {email, pass} <- Plug.BasicAuth.parse_basic_auth(conn),
         {:ok, user} <- ChinookHost.User.authenticate(email, pass) do
      %{current_user: user}
    else
      :error -> %{}
    end
  end
end
