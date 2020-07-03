defmodule ChinookWeb.PageController do
  use ChinookWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
