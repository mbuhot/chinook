defmodule ChinookWeb.Resolvers do
  alias Chinook.Album
  alias Chinook.Repo
  import Ecto.Query

  def list_albums(_parent, _args, _resolution) do
    query =
      from a in Album,
        select: %{
          id: a.album_id,
          title: a.title
        }
    data = Repo.all(query)
    {:ok, data}
  end
end
