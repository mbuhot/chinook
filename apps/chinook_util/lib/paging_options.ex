defmodule Chinook.Util.PagingOptions do
  @type t :: %{
          required(:by) => atom,
          optional(:after) => any,
          optional(:before) => any,
          optional(:first) => integer,
          optional(:last) => integer
        }
end
