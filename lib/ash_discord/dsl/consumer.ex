defmodule AshDiscord.Dsl.Consumer do
  @moduledoc """
  DSL entities and sections for consumer configuration.

  Provides the `ash_discord_consumer do` block for configuring AshDiscord consumers
  with granular resource and behavior settings.
  """

  alias Spark.Dsl.Section

  @ash_discord_consumer %Section{
    name: :ash_discord_consumer,
    describe: """
    Configure AshDiscord consumer behavior and resource mappings.

    Use this section to define domain mappings, resource configurations, and
    behavioral settings for the Discord consumer.
    """,
    examples: [
      """
      ash_discord_consumer do
        domains [MyApp.Chat, MyApp.Discord]
        guild_resource MyApp.Discord.Guild
        message_resource MyApp.Discord.Message
        user_resource MyApp.Accounts.User
        channel_resource MyApp.Discord.Channel
        store_bot_messages false
        debug_logging false
      end
      """
    ],
    schema: [
      domains: [
        type: {:list, :atom},
        required: true,
        doc: "List of Ash domains containing Discord commands"
      ],
      command_filter: [
        type: :atom,
        doc:
          "Command filter module implementing AshDiscord.CommandFilter behavior for guild-scoped command filtering"
      ],
      guild_resource: [
        type: :atom,
        doc: "Ash resource for Discord guilds"
      ],
      message_resource: [
        type: :atom,
        doc: "Ash resource for Discord messages"
      ],
      user_resource: [
        type: :atom,
        doc: "Ash resource for user accounts"
      ],
      channel_resource: [
        type: :atom,
        doc: "Ash resource for Discord channels"
      ],
      role_resource: [
        type: :atom,
        doc: "Ash resource for Discord roles"
      ],
      guild_member_resource: [
        type: :atom,
        doc: "Ash resource for Discord guild members"
      ],
      message_reaction_resource: [
        type: :atom,
        doc: "Ash resource for Discord message reactions"
      ],
      voice_state_resource: [
        type: :atom,
        doc: "Ash resource for Discord voice states"
      ],
      typing_indicator_resource: [
        type: :atom,
        doc: "Ash resource for Discord typing indicators"
      ],
      invite_resource: [
        type: :atom,
        doc: "Ash resource for Discord invites"
      ],
      interaction_resource: [
        type: :atom,
        doc: "Ash resource for Discord interactions"
      ],
      presence_resource: [
        type: :atom,
        doc: "Ash resource for Discord presence updates"
      ],
      store_bot_messages: [
        type: :boolean,
        default: false,
        doc: "Store messages from bot users"
      ],
      debug_logging: [
        type: :boolean,
        default: false,
        doc: "Enable debug logging for Discord events"
      ]
    ]
  }

  def ash_discord_consumer, do: @ash_discord_consumer
end
