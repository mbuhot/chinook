defmodule ChinookWeb.PlaylistTest do
  use Chinook.DataCase, async: true

  @query """
  query {
    playlists(last:2) {
      edges {
        node {
          id
          name
          tracks(first:1) {
            edges {
              node {
                id
                name
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
      "playlists" => %{
        "edges" => [
          %{
            "node" => %{
              "id" => "UGxheWxpc3Q6MTc=",
              "name" => "Heavy Metal Classic",
              "tracks" => %{
                "edges" => [
                  %{
                    "node" => %{
                      "id" => "VHJhY2s6MQ==",
                      "name" => "For Those About To Rock (We Salute You)"
                    }
                  }
                ]
              }
            }
          },
          %{
            "node" => %{
              "id" => "UGxheWxpc3Q6MTg=",
              "name" => "On-The-Go 1",
              "tracks" => %{
                "edges" => [
                  %{
                    "node" => %{
                      "id" => "VHJhY2s6NTk3",
                      "name" => "Now's The Time"
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

  test "query playlist" do
    assert Absinthe.run!(@query, ChinookWeb.Schema) == @expected
  end
end
