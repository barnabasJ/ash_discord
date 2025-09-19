defmodule AshDiscord.Consumer.Info do
  @moduledoc """
  Introspection for AshDiscord consumer configuration.

  Provides functions to retrieve consumer DSL configuration from modules
  using the AshDiscord.ConsumerExtension.

  The following functions are automatically generated from the DSL schema:
  - `ash_discord_consumer_domains/1` - Returns configured domains
  - `ash_discord_consumer_guild_resource/1` - Returns guild resource
  - `ash_discord_consumer_message_resource/1` - Returns message resource
  - `ash_discord_consumer_user_resource/1` - Returns user resource
  - `ash_discord_consumer_channel_resource/1` - Returns channel resource
  - `ash_discord_consumer_role_resource/1` - Returns role resource
  - `ash_discord_consumer_guild_member_resource/1` - Returns guild member resource
  - `ash_discord_consumer_message_reaction_resource/1` - Returns message reaction resource
  - `ash_discord_consumer_voice_state_resource/1` - Returns voice state resource
  - `ash_discord_consumer_typing_indicator_resource/1` - Returns typing indicator resource
  - `ash_discord_consumer_invite_resource/1` - Returns invite resource
  - `ash_discord_consumer_auto_create_users/1` - Returns auto_create_users setting
  - `ash_discord_consumer_store_bot_messages/1` - Returns store_bot_messages setting
  - `ash_discord_consumer_debug_logging/1` - Returns debug_logging setting
  - `ash_discord_consumer_enable_callbacks/1` - Returns enabled callbacks
  - `ash_discord_consumer_disable_callbacks/1` - Returns disabled callbacks
  - `ash_discord_consumer_options/1` - Returns all configuration options as a map
  """

  use Spark.InfoGenerator,
    extension: AshDiscord.ConsumerExtension,
    sections: [:ash_discord_consumer]
end