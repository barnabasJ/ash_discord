import Config

config :ash_discord,
  ash_domains: [TestApp.Discord]

config :logger,
  level: :info,
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
