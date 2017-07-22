defmodule ExistExtras.Mixfile do
  use Mix.Project

  def project do
    [app: :exist_extras,
     version: "0.1.0",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:redix, :maru, :httpoison],
      extra_applications: [:logger]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:redix, "~> 0.5.1"},
      {:maru, github: "elixir-maru/maru"},
      {:mustache, "~> 0.0.2"},
      {:httpoison, "~> 0.11.1"},
      {:joken, "~> 1.1"},
      {:exvcr, "~> 0.8", only: :test}
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]
end
