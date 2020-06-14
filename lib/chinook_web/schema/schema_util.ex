defmodule ChinookWeb.SchemaUtil do
  def batch(mod, fun, args, key) do
    Absinthe.Resolution.Helpers.batch(
      {mod, fun, args},
      key,
      &{:ok, Map.get(&1, key)}
    )
  end

  def connection_batch(mod, fun, args, key) do
    {:ok, offset} = Absinthe.Relay.Connection.offset(args)
    Absinthe.Resolution.Helpers.batch(
      {mod, fun, args},
      key,
      fn batch_result ->
        data = Map.get(batch_result, key, [])
        Absinthe.Relay.Connection.from_slice(data, offset)
      end
    )
  end
end
