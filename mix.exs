defmodule Borscht.MixProject do
  use Mix.Project

  @version "0.0.1"
  @name "Borscht"
  @github_url "https://github.com/BlueHotDog/borscht"

  def project do
    [
      app: @name |> String.downcase() |> String.to_atom(),
      name: @name,
      version: @version,
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      package: package(),
      deps: deps(),
      description: "Plugin based exception reporting for elixir.",
      homepage_url: "https://github.com/BlueHotDog/borscht",
      docs: [
        main: @name,
        source_ref: "v#{@version}",
        source_url: @github_url
      ],
      dialyzer: [plt_add_deps: :project]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:httpoison, :logger, :jason],
      env: env(),
      mod: {Borscht, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:jason, "~> 1.0"},
      # Dev dependencies
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, "~> 0.5.1", only: [:test, :dev]},
      {:apex, "~> 1.2", only: [:test, :dev]}
    ]
  end

  defp package() do
    [
      maintainers: ["Danni Friedland"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github_url}
    ]
  end

  defp env() do
    [
      enabled: true,
      environment_name: Mix.env(),
      exclude_envs: [:dev, :test],
      reporters: [Borscht.Reporter.Console]
    ]
  end
end
