defmodule Chinkook.API.ErrorJSONTest do
  use ChinookWeb.ConnCase, async: true

  test "renders 404" do
    assert ChinookWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ChinookWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
