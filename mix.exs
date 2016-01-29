defmodule WokEspec.Mixfile do
  use Mix.Project

  def project do
    [app: :wok_espec,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     preferred_cli_env: [espec: :test],
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:espec, "~> 0.8.8"},
     {:httpoison, "~> 0.8.0"},
     {:poison, "~> 1.5"},
     {:cowboy, ~r/.*/, git: "https://github.com/ninenines/cowboy.git", branch: "master"}]
  end
end
