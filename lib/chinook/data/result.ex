defmodule Chinook.Result do
  def ok(x), do: {:ok, x}
  def error(x), do: {:error, x}

  # todo: map, map_error, bind, apply
end
