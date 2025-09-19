import Config

# Configure ETS data layer for testing
config :ash, :use_all_identities_in_manage_relationship?, false
config :ash, :disable_async?, true
config :ash, :validate_domain_config_inclusion?, false

config :ash, :compatible_foreign_key_types, [
  {Ash.Type.UUID, Ash.Type.Integer},
  {Ash.Type.Integer, Ash.Type.UUID},
  {Ash.Type.String, Ash.Type.Integer},
  {Ash.Type.Integer, Ash.Type.String}
]

# Configure the test app
config :test_app,
  ash_domains: [TestApp.Discord]

# Configure ash_discord domains
config :ash_discord,
  ash_domains: [TestApp.Discord]

# Configure Discord settings for testing
config :ash_discord,
  application_id: "123456789012345678",
  public_key: "test_public_key",
  bot_token: "test_bot_token"
