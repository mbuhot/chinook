defmodule ChinookHost.PageController do
  use ChinookHost, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
