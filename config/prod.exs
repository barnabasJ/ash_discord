import Config

# Configure the database
config :ash_discord, TestApp.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10")),
  socket_options: [:inet6]

config :logger, level: :info
