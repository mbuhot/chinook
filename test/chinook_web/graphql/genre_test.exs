defmodule ChinookWeb.GenreTest do
  use Chinook.DataCase, async: true

  test "query genre" do
    query = """
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

    expected = %{
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

    assert Absinthe.run!(query, ChinookWeb.Schema) == expected
  end

  test "query genre with tracks sorted by artist name" do
    query = """
    query {
      genres(first: 1){
        edges{
          node {
            name
            tracks(last:5, by: ARTIST_NAME, before:"YXJ0aXN0X25hbWV8dHJhY2tfaWR8MzEwNg=="){
              edges {
                cursor
                node {
                  name
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
    """

    expected = %{
      data: %{
        "genres" => %{
          "edges" => [
            %{
              "node" => %{
                "name" => "Rock",
                "tracks" => %{
                  "edges" => [
                    %{
                      "node" => %{"name" => "Primary", "artist" => %{"name" => "Van Halen"}},
                      "cursor" => "YXJ0aXN0X25hbWV8dHJhY2tfaWR8MzEwMQ=="
                    },
                    %{
                      "node" => %{
                        "name" => "Ballot or the Bullet",
                        "artist" => %{"name" => "Van Halen"}
                      },
                      "cursor" => "YXJ0aXN0X25hbWV8dHJhY2tfaWR8MzEwMg=="
                    },
                    %{
                      "node" => %{
                        "name" => "How Many Say I",
                        "artist" => %{"name" => "Van Halen"}
                      },
                      "cursor" => "YXJ0aXN0X25hbWV8dHJhY2tfaWR8MzEwMw=="
                    },
                    %{
                      "cursor" => "YXJ0aXN0X25hbWV8dHJhY2tfaWR8MzEwNA==",
                      "node" => %{
                        "artist" => %{"name" => "Velvet Revolver"},
                        "name" => "Sucker Train Blues"
                      }
                    },
                    %{
                      "cursor" => "YXJ0aXN0X25hbWV8dHJhY2tfaWR8MzEwNQ==",
                      "node" => %{
                        "artist" => %{"name" => "Velvet Revolver"},
                        "name" => "Do It For The Kids"
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

    assert Absinthe.run!(query, ChinookWeb.Schema) == expected
  end
end
