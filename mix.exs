defmodule Voting.Mixfile do
  use Mix.Project

  def project do
    [app: :voting,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {Voting.Application, []}]
  end

  defp deps do
    [
      {:gproc,"~> 0.6.1"},
      {:gen_stage, "~> 0.11.0"}
    ]
  end
end
