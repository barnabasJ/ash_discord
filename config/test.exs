import Config

config :ash_discord, TestApp.Repo,
  username: System.get_env("DATABASE_USER") || "postgres",
  password: System.get_env("DATABASE_PASSWORD") || "postgres",
  hostname: System.get_env("DATABASE_HOST") || "localhost",
  database: "ash_discord_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  priv: "priv/test_repo"

config :ash_discord,
  ecto_repos: [TestApp.Repo],
  ash_domains: [TestApp.Discord]

config :logger,
  level: :debug,
  backends: [:console],
  console: [
    format: "$time [$level] $message $metadata\n",
    metadata: :all
  ]

# Configure Nostrum for tests - disable real connections
config :nostrum,
  token: "dummy",
  num_shards: :manual,
  streamlink: false

# Configure test application
config :ash_discord, TestApp.Application, start_apps: [:postgrex, :phoenix_pubsub]
