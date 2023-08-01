defmodule ChinookWeb.Router do
  use ChinookWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug ChinookWeb.GraphQLContext
  end

  scope "/api" do
    pipe_through :api
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: Chinook.API.Schema
    forward "/", Absinthe.Plug, schema: Chinook.API.Schema
  end
end
