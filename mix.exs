defmodule AshDiscord.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "A Discord integration library for Ash Framework with Spark DSL support"
  @source_url "https://github.com/ash-project/ash_discord"

  def project do
    [
      app: :ash_discord,
      version: @version,
      description: @description,
      package: package(),
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_coverages: [
        "coveralls",
        "coveralls.detail",
        "coveralls.html"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core dependencies
      {:ash, "~> 3.0"},
      {:spark, "~> 2.0"},
      {:nostrum, "~> 0.10", optional: true, runtime: Mix.env() != :test},

      # Test dependencies for database and resources
      {:ash_postgres, "~> 2.0", only: :test},
      {:ecto_sql, "~> 3.10", only: :test},
      {:postgrex, "~> 0.17", only: :test},
      {:phoenix_pubsub, "~> 2.1", only: :test},

      # Development and testing
      {:sourceror, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mimic, "~> 1.7", only: :test},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp package do
    [
      name: :ash_discord,
      maintainers: ["AshDiscord Team"],
      licenses: ["MIT"],
      links: %{
        GitHub: @source_url
      },
      files: ~w(lib .formatter.exs mix.exs README* CHANGELOG* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "AshDiscord",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end

  defp aliases do
    [
      # Code quality aliases
      credo: "credo --strict",
      format: "format",
      quality: ["format", "credo --strict", "dialyzer"],

      # Test environment setup aliases  
      "test.setup": &test_setup/1,
      "test.migrate": ["cmd MIX_ENV=test mix ash.migrate"],
      "test.rollback": ["cmd MIX_ENV=test mix ash.rollback"], 
      "test.reset": &test_reset/1,
      "test.tear_down": ["cmd MIX_ENV=test mix ash.tear_down"],

      # Test coverage aliases
      "test.coverage": ["coveralls"],
      "test.coverage.html": ["coveralls.html"],
      "test.coverage.detail": ["coveralls.detail"],

      # Development aliases
      "deps.clean": ["deps.clean", "deps.compile"],
      docs: ["docs", "cmd open doc/index.html"],

      # Ash-specific aliases
      "spark.formatter": "spark.formatter --extensions AshDiscord",
      "format.all": ["format", "spark.formatter --extensions AshDiscord"]
    ]
  end

  defp test_setup(_) do
    Mix.shell().cmd("MIX_ENV=test mix ecto.create")
    Mix.shell().cmd("MIX_ENV=test mix ash.setup")
  end

  defp test_reset(_) do
    Mix.shell().cmd("MIX_ENV=test mix ecto.drop")
    Mix.shell().cmd("MIX_ENV=test mix ecto.create")
    Mix.shell().cmd("MIX_ENV=test mix ash.setup")
  end
end
