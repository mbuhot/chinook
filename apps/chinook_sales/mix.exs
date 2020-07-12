defmodule ChinookSales.MixProject do
  use Mix.Project

  def project do
    [
      app: :chinook_sales,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
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

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:chinook_catalog, in_umbrella: true, only: :test},
      {:chinook_repo, in_umbrella: true, only: :test},
      {:chinook_util, in_umbrella: true},
      {:ecto, "~> 3.4"}
    ]
  end
end
