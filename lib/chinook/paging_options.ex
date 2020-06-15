defmodule Chinook.PagingOptions do
  @type t :: %{
          required(:cursor_field) => atom,
          optional(:after) => any,
          optional(:before) => any,
          optional(:first) => integer,
          optional(:last) => integer
        }
end
