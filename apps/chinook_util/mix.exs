defmodule ChinookUtil.MixProject do
  use Mix.Project

  def project do
    [
      app: :chinook_util,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:absinthe,
       github: "mbuhot/absinthe", branch: "fix-introspect-nullable-scalar-input", override: true},
      {:absinthe_relay, "~> 1.5"},
      {:dataloader, github: "absinthe-graphql/dataloader", override: true},
      {:ecto, "~> 3.4"}
    ]
  end
end
