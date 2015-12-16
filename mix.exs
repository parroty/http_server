defmodule HttpServer.Mixfile do
  use Mix.Project

  def project do
    [ app: :http_server,
      version: "0.0.2",
      elixir: "~> 1.0",
      deps: deps(Mix.env)
    ]
  end

  # Configuration for the OTP application
  def application do
    [
      applications: [:crypto, :cowboy],
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
        {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.2"},
        {:httpotion, "~> 2.1.0"}
      ]
  end

  def deps(:prod) do
    [
      {:cowboy, "~> 1.0"}
    ]
  end
end
