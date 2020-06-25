defmodule ChinookWeb.CursorTest do
  use Chinook.DataCase, async: true

  @query """
  query {
    artists(first:2, by:NAME, after:"eyJhdCI6eyJhcnRpc3RfaWQiOjJ9LCJieSI6Im5hbWUifQ=="){
      pageInfo {
        hasPreviousPage
        hasNextPage
        endCursor
        startCursor
      }
      edges {
        cursor
        node {
          name
        }
      }
    }
  }
  """

  @expected %{
    data: %{
      "artists" => %{
        "edges" => [
          %{
            "cursor" => "eyJhdCI6eyJhcnRpc3RfaWQiOjI2MH0sImJ5IjoibmFtZSJ9",
            "node" => %{
              "name" => "Adrian Leaper & Doreen de Feis"
            }
          },
          %{
            "cursor" => "eyJhdCI6eyJhcnRpc3RfaWQiOjN9LCJieSI6Im5hbWUifQ==",
            "node" => %{"name" => "Aerosmith"}
          }
        ],
        "pageInfo" => %{
          "endCursor" => "eyJhdCI6eyJhcnRpc3RfaWQiOjN9LCJieSI6Im5hbWUifQ==",
          "hasNextPage" => true,
          "hasPreviousPage" => true,
          "startCursor" => "eyJhdCI6eyJhcnRpc3RfaWQiOjI2MH0sImJ5IjoibmFtZSJ9"
        }
      }
    }
  }

  test "query artists with cursor" do
    assert Absinthe.run!(@query, ChinookWeb.Schema) == @expected
  end
end
