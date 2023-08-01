defmodule Chinkook.API.ArtistTest do
  use Chinook.DataCase, async: true

  @query """
  query {
    artists(first: 2) {
      edges {
        node {
          id
          name
          albums(last: 1) {
            edges {
              node {
                id
                title
                tracks(first: 2) {
                  edges {
                    node {
                      id
                      name
                      genre {
                        id
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
    }
  }
  """

  @expected %{
    data: %{
      "artists" => %{
        "edges" => [
          %{
            "node" => %{
              "albums" => %{
                "edges" => [
                  %{
                    "node" => %{
                      "id" => "QWxidW06NA==",
                      "title" => "Let There Be Rock",
                      "tracks" => %{
                        "edges" => [
                          %{
                            "node" => %{
                              "genre" => %{"id" => "R2VucmU6MQ==", "name" => "Rock"},
                              "id" => "VHJhY2s6MTU=",
                              "name" => "Go Down"
                            }
                          },
                          %{
                            "node" => %{
                              "genre" => %{"id" => "R2VucmU6MQ==", "name" => "Rock"},
                              "id" => "VHJhY2s6MTY=",
                              "name" => "Dog Eat Dog"
                            }
                          }
                        ]
                      }
                    }
                  }
                ]
              },
              "id" => "QXJ0aXN0OjE=",
              "name" => "AC/DC"
            }
          },
          %{
            "node" => %{
              "albums" => %{
                "edges" => [
                  %{
                    "node" => %{
                      "id" => "QWxidW06Mw==",
                      "title" => "Restless and Wild",
                      "tracks" => %{
                        "edges" => [
                          %{
                            "node" => %{
                              "genre" => %{"id" => "R2VucmU6MQ==", "name" => "Rock"},
                              "id" => "VHJhY2s6Mw==",
                              "name" => "Fast As a Shark"
                            }
                          },
                          %{
                            "node" => %{
                              "genre" => %{"id" => "R2VucmU6MQ==", "name" => "Rock"},
                              "id" => "VHJhY2s6NA==",
                              "name" => "Restless and Wild"
                            }
                          }
                        ]
                      }
                    }
                  }
                ]
              },
              "id" => "QXJ0aXN0OjI=",
              "name" => "Accept"
            }
          }
        ]
      }
    }
  }

  test "query artists" do
    assert Absinthe.run!(@query, Chinook.API.Schema) == @expected
  end
end
