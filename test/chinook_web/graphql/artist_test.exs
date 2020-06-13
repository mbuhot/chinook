defmodule ChinookWeb.ArtistTest do
  use Chinook.DataCase, async: true

  test "query artists" do
    """
    query {
      artists(first: 2) {
        id
        name
        albums(last: 1) {
          id
          title
          tracks(first: 2) {
            id
            name
            genre {
              id
              name
            }
          }
        }
      }
    }
    """
    |> Absinthe.run!(ChinookWeb.Schema)
    |> case do
      %{data: data} ->
        assert %{
                 "artists" => [
                   %{
                     "id" => _,
                     "albums" => [%{"title" => _, "tracks" => [%{"name" => _}, %{"name" => _}]}]
                   },
                   %{
                     "id" => _,
                     "albums" => [%{"title" => _, "tracks" => [%{"name" => _}, %{"name" => _}]}]
                   }
                 ]
               } = data
    end
  end
end
