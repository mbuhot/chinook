defmodule ChinookWeb.CursorTest do
  use Chinook.DataCase, async: true

  @query """
  query {
    artists(first:2, by:NAME, after:"bmFtZTpBQy9EQw=="){
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
            "cursor" => "bmFtZTpBYXJvbiBDb3BsYW5kICYgTG9uZG9uIFN5bXBob255IE9yY2hlc3RyYQ==",
            "node" => %{
              "name" => "Aaron Copland & London Symphony Orchestra"
            }
          },
          %{
            "cursor" => "bmFtZTpBYXJvbiBHb2xkYmVyZw==",
            "node" => %{
              "name" => "Aaron Goldberg"
            }
          }
        ],
        "pageInfo" => %{
          "endCursor" => "bmFtZTpBYXJvbiBHb2xkYmVyZw==",
          "hasNextPage" => false,
          "hasPreviousPage" => false,
          "startCursor" => "bmFtZTpBYXJvbiBDb3BsYW5kICYgTG9uZG9uIFN5bXBob255IE9yY2hlc3RyYQ=="
        }
      }
    }
  }

  test "query artists with cursor" do
    assert Absinthe.run!(@query, ChinookWeb.Schema) == @expected
  end
end
