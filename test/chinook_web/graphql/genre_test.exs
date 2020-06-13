defmodule ChinookWeb.GenreTest do
  use Chinook.DataCase, async: true

  test "query genre" do
    """
    query {
      genres(first: 3){
        name,
        tracks(first:1){
          name,
          album {
            title
            artist {
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
                 "genres" => [
                   %{
                     "name" => "Rock",
                     "tracks" => [
                       %{
                         "album" => %{
                           "artist" => %{"name" => "AC/DC"},
                           "title" => "For Those About To Rock We Salute You"
                         },
                         "name" => "For Those About To Rock (We Salute You)"
                       }
                     ]
                   },
                   %{
                     "name" => "Jazz",
                     "tracks" => [
                       %{
                         "album" => %{
                           "artist" => %{"name" => "Antônio Carlos Jobim"},
                           "title" => "Warner 25 Anos"
                         },
                         "name" => "Desafinado"
                       }
                     ]
                   },
                   %{
                     "name" => "Metal",
                     "tracks" => [
                       %{
                         "album" => %{
                           "artist" => %{"name" => "Apocalyptica"},
                           "title" => "Plays Metallica By Four Cellos"
                         },
                         "name" => "Enter Sandman"
                       }
                     ]
                   }
                 ]
               } = data
    end
  end
end
