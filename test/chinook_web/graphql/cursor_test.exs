defmodule ChinookWeb.CursorTest do
  use Chinook.DataCase, async: true

  @query """
  query {
    artists(first:2, by:NAME, after:"bmFtZXxhcnRpc3RfaWR8Mg=="){
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
            "cursor" => "bmFtZXxhcnRpc3RfaWR8MjYw",
            "node" => %{
              "name" => "Adrian Leaper & Doreen de Feis"
            }
          },
          %{
            "cursor" => "bmFtZXxhcnRpc3RfaWR8Mw==",
            "node" => %{"name" => "Aerosmith"}
          }
        ],
        "pageInfo" => %{
          "endCursor" => "bmFtZXxhcnRpc3RfaWR8Mw==",
          "hasNextPage" => true,
          "hasPreviousPage" => true,
          "startCursor" => "bmFtZXxhcnRpc3RfaWR8MjYw"
        }
      }
    }
  }

  test "query artists with cursor" do
    assert Absinthe.run!(@query, ChinookWeb.Schema) == @expected
  end
end
