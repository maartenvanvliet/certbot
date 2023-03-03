defmodule Certbot.MixProject do
  use Mix.Project

  @version "0.5.1"
  def project do
    [
      app: :certbot,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Certbot",
      source_url: "https://github.com/maartenvanvliet/certbot",
      homepage_url: "https://github.com/maartenvanvliet/certbot",
      description:
        "Provide dynamic ssl-certificates for your Phoenix or Plug app using Letsencrypt",
      package: [
        maintainers: ["Maarten van Vliet"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/maartenvanvliet/certbot"},
        files: ~w(LICENSE README.md lib mix.exs)
      ],
      docs: [
        main: "Certbot",
        canonical: "http://hexdocs.pm/certbot",
        source_url: "https://github.com/maartenvanvliet/certbot",
        nest_modules_by_prefix: [Certbot.Acme]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:acme, "~> 0.5.1"},
      {:x509, "~> 0.8.0"},
      {:ex_doc, "~> 0.29.2", only: :dev},
      {:plug, "~> 1.7"},
      {:jose, "~> 1.9"},
      {:credo, "~> 1.5.0", only: [:dev, :test], runtime: false}
    ]
  end
end
