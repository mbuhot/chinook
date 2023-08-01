defmodule Chinkook.API.ArtistNodeTest do
  use Chinook.DataCase, async: true

  @query """
  query {
    node (id: "QXJ0aXN0OjE=") {
      id
      ... on Artist {
        name
        albums {
          edges {
            node {
              title
            }
          }
        }
      }
    }
  }
  """

  @expected %{
    data: %{
      "node" => %{
        "albums" => %{
          "edges" => [
            %{
              "node" => %{
                "title" => "For Those About To Rock We Salute You"
              }
            },
            %{
              "node" => %{
                "title" => "Let There Be Rock"
              }
            }
          ]
        },
        "id" => "QXJ0aXN0OjE=",
        "name" => "AC/DC"
      }
    }
  }

  test "query artist_node" do
    assert Absinthe.run!(@query, Chinook.API.Schema) == @expected
  end
end
