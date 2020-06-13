defmodule ChinookWeb.SchemaUtil do
  def batch(mod, fun, args, key) do
    Absinthe.Resolution.Helpers.batch(
      {mod, fun, args},
      key,
      &{:ok, Map.get(&1, key)}
    )
  end
end
