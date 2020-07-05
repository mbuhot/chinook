defmodule ChinookHost.Router do
  use ChinookHost, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ChinookHost.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug ChinookHost.GraphQLContext
  end

  scope "/", ChinookHost do
    pipe_through :browser

    live "/", PageLive, :index
  end

  scope "/api" do
    pipe_through :api
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: Chinook.GraphQL.Schema
    forward "/", Absinthe.Plug, schema: Chinook.GraphQL.Schema
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: ChinookHost.Telemetry
    end
  end
end
