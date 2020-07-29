defmodule Chinook.Loader do

  def load(server, source_name, batch_key, val) do
    send_request(server, {:load, source_name, batch_key, val})
  end

  def load_many(server, source_name, batch_key, values) do
    send_request(server, {:load_many, source_name, batch_key, values})
  end

  defp send_request(server, message) do
    :gen_server.send_request(server, message) |> IO.inspect()
  end

  defmodule Server do
    use GenServer
    require Logger

    def start_link(loader, opts \\ []) do
      GenServer.start_link(__MODULE__, loader, opts)
    end

    @impl true
    def init(loader) do
      {:ok, %{loader: loader, requests: [], loading: false}}
    end

    @impl true
    def handle_call(msg = {:load, source_name, batch_key, val}, sender, state = %{loader: loader}) do
      loader = Dataloader.load(loader, source_name, batch_key, val)
      add_request(msg, sender, loader, state)
    end

    @impl true
    def handle_call(msg = {:load_many, source_name, batch_key, vals}, sender, state = %{loader: loader}) do
      loader = Dataloader.load_many(loader, source_name, batch_key, vals)
      add_request(msg, sender, loader, state)
    end

    defp add_request(msg, sender, loader, state) do
      requests = [{sender, msg} | state.requests]
      state = %{state | loader: loader, requests: requests}
      if state.loading do
        {:noreply, state}
      else
        Process.send_after(self(), :run, 0)
        {:noreply, %{state | loading: true}}
      end
    end

    @impl true
    def handle_info(:run, state = %{loader: loader, requests: requests}) do
      Logger.info("Running dataloader batch, size: #{Enum.count(requests)}")
      loader = Dataloader.run(loader)
      Enum.each(requests, fn
        {sender, {:load, source_name, batch_key, val}} ->
          data = Dataloader.get(loader, source_name, batch_key, val)
          GenServer.reply(sender, data)

        {sender, {:load_many, source_name, batch_key, vals}} ->
          data = Dataloader.get_many(loader, source_name, batch_key, vals)
          GenServer.reply(sender, data)
      end)

      {:noreply, %{state | loader: loader, requests: [], loading: false}}
    end
  end
end
