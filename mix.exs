defmodule Postal.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/levibuzolic/postal"

  def project do
    [
      app: :postal,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      name: "Postal",
      description:
        "Elixir bindings for libpostal — fast address parsing and normalization via Rust NIF",
      source_url: @source_url,
      homepage_url: @source_url,
      dialyzer: [
        plt_add_apps: [:mix],
        plt_local_path: "_build/dialyzer"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.37.3"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "libpostal" => "https://github.com/openvenues/libpostal"
      },
      files:
        ~w(lib native/postal_nif/src native/postal_nif/Cargo.toml native/postal_nif/Cargo.lock .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "Postal",
      extras: ["README.md", "LICENSE"]
    ]
  end
end
