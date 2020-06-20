defmodule ChinookWeb.Schema.Filter do
  use Absinthe.Schema.Notation

  @desc "String filter"
  input_object :string_filter do
    @desc "SQL style pattern with %"
    field :like, :string

    @desc "String starts with the given string"
    field :starts_with, :string

    @desc "String ends with the given string"
    field :ends_with, :string
  end

  @desc "Integer filter"
  input_object :int_filter do
    field :gt, :integer
    field :gte, :integer
    field :eq, :integer
    field :ne, :integer
    field :lt, :integer
    field :lte, :integer
  end

  @desc "Decimal filter"
  input_object :decimal_filter do
    field :gt, :decimal
    field :gte, :decimal
    field :eq, :decimal
    field :ne, :decimal
    field :lt, :decimal
    field :lte, :decimal
  end

  @desc "DateTime filter"
  input_object :datetime_filter do
    field :before, :datetime
    field :after, :datetime
  end
end
