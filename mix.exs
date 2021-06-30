defmodule Scrivener.Headers.Mixfile do
  use Mix.Project

  @version "3.1.1"

  def project do
    [app: :scrivener_headers,
     version: @version,
     elixir: "~> 1.4",
     package: package(),
     description: """
     Helpers for paginating API responses with Scrivener and HTTP headers
     """,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def package do
    [maintainers: ["Sean Callan"],
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/beam-community/scrivener_headers"}]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [
      {:plug, "~> 1.3", optional: true},
      {:scrivener, "~> 2.3"},

      {:credo, "~> 0.8.6", only: [:dev, :test]},
      {:ex_doc, "~> 0.15", only: :dev}
    ]

  end
end
