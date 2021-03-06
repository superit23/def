defmodule Def.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     preferred_cli_env: [
       "coveralls": :test,
       "coveralls.html": :test,
       "coveralls.json": :test
     ],
     test_coverage: [tool: ExCoveralls]
   ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps do
    [{:excoveralls, "~> 0.7.1", only: :test},
     {:inch_ex, only: :docs},
     {:credo, "~> 0.8", only: [:dev, :test], runtime: false}]
  end
end
