import Config

# Configure Ecto repos for database operations
config :ash_discord, ecto_repos: [TestApp.Repo]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
