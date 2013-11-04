defmodule HttpServer.Mixfile do
  use Mix.Project

  def project do
    [ app: :http_server,
      version: "0.0.1",
      elixir: ">= 0.10.3",
      deps: deps(Mix.env)
    ]
  end

  # Configuration for the OTP application
  def application do
    [
      applications: [:ranch, :crypto, :cowboy],
      mod: { HttpServer, [] }
    ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "~> 0.1", git: "https://github.com/elixir-lang/foobar.git" }
  def deps(:test) do
    deps(:dev)
  end

  def deps(:dev) do
    deps(:prod) ++
      [
        {:httpotion, github: "parroty/httpotion", branch: "version"},
      ]
  end

  def deps(:prod) do
    [
      {:ranch, github: "extend/ranch", ref: "0.8.5", override: true},
      {:cowlib, github: "extend/cowlib", ref: "0.3.0", override: true},
      {:cowboy, github: "extend/cowboy"}
    ]
  end
end
