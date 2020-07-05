defmodule Chinook.Sales.Loader do
  alias Chinook.Sales.{Customer, Employee, Invoice}

  def add(loader) do
    loader
    |> Dataloader.add_source(
      __MODULE__,
      Dataloader.Ecto.new(ChinookRepo,
        query: fn
          Customer, args -> Customer.Loader.query(args)
          Employee, args -> Employee.Loader.query(args)
          Invoice, args -> Invoice.Loader.query(args)
          Invoice.Line, _args -> Invoice.Line
        end
      )
    )
  end
end
