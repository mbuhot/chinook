defmodule ChinookWeb.Schema.Track do
  use Absinthe.Schema.Notation

  object :track do
    field :id, :id
    field :name, non_null(:string)
    field :genre, non_null(:string)
  end
end
