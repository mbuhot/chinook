defmodule Chinook.Sales.CustomerTest do
  use ChinookRepo.DataCase, async: true

  @query """
  query {
    customers(first: 2) {
      edges {
        node {
          id
          email
          tracks(first: 2) {
            edges {
              node {
                id
                name
              }
            }
          }
          invoices(last: 1) {
            edges {
              node {
                id
                invoiceDate
                total
                lineItems {
                  unitPrice
                  quantity
                  track {
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
      "customers" => %{
        "edges" => [
          %{
            "node" => %{
              "email" => "luisg@embraer.com.br",
              "id" => "Q3VzdG9tZXI6MQ==",
              "invoices" => %{
                "edges" => [
                  %{
                    "node" => %{
                      "id" => "SW52b2ljZTozODI=",
                      "invoiceDate" => "2013-08-07T00:00:00",
                      "lineItems" => [
                        %{
                          "quantity" => 1,
                          "track" => %{
                            "name" => "Vamo Batê Lata"
                          },
                          "unitPrice" => "0.99"
                        },
                        %{
                          "quantity" => 1,
                          "track" => %{
                            "name" => "Mensagen De Amor (2000)"
                          },
                          "unitPrice" => "0.99"
                        },
                        %{
                          "quantity" => 1,
                          "track" => %{
                            "name" => "Saber Amar"
                          },
                          "unitPrice" => "0.99"
                        },
                        %{
                          "quantity" => 1,
                          "track" => %{
                            "name" => "Cinema Mudo"
                          },
                          "unitPrice" => "0.99"
                        },
                        %{
                          "quantity" => 1,
                          "track" => %{
                            "name" => "Meu Erro"
                          },
                          "unitPrice" => "0.99"
                        },
                        %{
                          "quantity" => 1,
                          "track" => %{
                            "name" => "Será Que Vai Chover?"
                          },
                          "unitPrice" => "0.99"
                        },
                        %{
                          "quantity" => 1,
                          "track" => %{
                            "name" => "Mama, I'm Coming Home"
                          },
                          "unitPrice" => "0.99"
                        },
                        %{
                          "quantity" => 1,
                          "track" => %{
                            "name" => "Flying High Again"
                          },
                          "unitPrice" => "0.99"
                        },
                        %{
                          "quantity" => 1,
                          "track" => %{
                            "name" => "Paranoid"
                          },
                          "unitPrice" => "0.99"
                        }
                      ],
                      "total" => "8.91"
                    }
                  }
                ]
              },
              "tracks" => %{
                "edges" => [
                  %{"node" => %{"id" => "VHJhY2s6MjYy", "name" => "Interlude Zumbi"}},
                  %{"node" => %{"id" => "VHJhY2s6Mjcx", "name" => "Rios Pontes & Overdrives"}}
                ]
              }
            }
          },
          %{
            "node" => %{
              "email" => "leonekohler@surfeu.de",
              "id" => "Q3VzdG9tZXI6Mg==",
              "invoices" => %{
                "edges" => [
                  %{
                    "node" => %{
                      "id" => "SW52b2ljZToyOTM=",
                      "invoiceDate" => "2012-07-13T00:00:00",
                      "lineItems" => [
                        %{
                          "quantity" => 1,
                          "track" => %{
                            "name" => "Boris The Spider"
                          },
                          "unitPrice" => "0.99"
                        }
                      ],
                      "total" => "0.99"
                    }
                  }
                ]
              },
              "tracks" => %{
                "edges" => [
                  %{"node" => %{"id" => "VHJhY2s6Mg==", "name" => "Balls to the Wall"}},
                  %{"node" => %{"id" => "VHJhY2s6NA==", "name" => "Restless and Wild"}}
                ]
              }
            }
          }
        ]
      }
    }
  }

  test "query customers" do
    user = Chinook.Sales.Employee |> ChinookRepo.get_by!(title: "General Manager")
    assert Absinthe.run!(@query, Chinook.Sales.TestSchema, context: %{current_user: user}) == @expected
  end
end
