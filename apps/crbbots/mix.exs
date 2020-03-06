defmodule Bot.MixProject do
  use Mix.Project

  def project do
    [
      app: :crbbots,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Crb.Application, []}, # Start module
      applications: [:gun,:nadia, :timex],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:distillery, "~> 2.0"},
      {:httpoison, "~> 1.6.0", override: true},
      {:poison, "~> 3.1"},
      {:gun, "~> 1.0"},
      {:gen_stage, "~> 0.0"},
      {:decimal, "~> 1.0"},
      {:elmdb, "~> 0.4.1"},
      {:timex, "~> 3.1"},
      {:nadia, "~> 0.4.4" },
      {:logger_file_backend, "~> 0.0.10"}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end

