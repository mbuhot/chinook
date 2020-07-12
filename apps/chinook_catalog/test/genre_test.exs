defmodule Chinook.Catalog.GenreTest do
  use ChinookRepo.DataCase, async: true

  @query """
  query {
    genres(first: 1){
      edges{
        node {
          name
          tracks(first:3){
            edges {
              node{
                name
                album {
                  title
                  artist {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  """

  @expected %{
    data: %{
      "genres" => %{
        "edges" => [
          %{
            "node" => %{
              "name" => "Rock",
              "tracks" => %{
                "edges" => [
                  %{
                    "node" => %{
                      "album" => %{
                        "artist" => %{"name" => "AC/DC"},
                        "title" => "For Those About To Rock We Salute You"
                      },
                      "name" => "For Those About To Rock (We Salute You)"
                    }
                  },
                  %{
                    "node" => %{
                      "album" => %{
                        "artist" => %{"name" => "Accept"},
                        "title" => "Balls to the Wall"
                      },
                      "name" => "Balls to the Wall"
                    }
                  },
                  %{
                    "node" => %{
                      "album" => %{
                        "artist" => %{"name" => "Accept"},
                        "title" => "Restless and Wild"
                      },
                      "name" => "Fast As a Shark"
                    }
                  }
                ]
              }
            }
          }
        ]
      }
    }
  }

  test "query genre" do
    assert Absinthe.run!(@query, Chinook.Catalog.TestSchema) == @expected
  end
end
