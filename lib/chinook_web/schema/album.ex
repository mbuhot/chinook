defmodule ChinookWeb.Schema.Album do
  use Absinthe.Schema.Notation

  object :album do
    field :id, :id
    field :title, non_null(:string)
  end
end
