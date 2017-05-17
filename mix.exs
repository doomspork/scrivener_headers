defmodule Scrivener.Headers.Mixfile do
  use Mix.Project

  @version "3.0.0"

  def project do
    [app: :scrivener_headers,
     version: @version,
     elixir: "~> 1.3",
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
     links: %{github: "https://github.com/doomspork/scrivener_headers"}]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:plug, "~> 1.2", optional: true},
     {:scrivener, "~> 2.1"},
     {:ex_doc, "~> 0.13.0", only: :dev}]
  end
end
