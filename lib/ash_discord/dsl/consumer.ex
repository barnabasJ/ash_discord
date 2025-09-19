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
        auto_create_users true
        store_bot_messages false
        debug_logging false
        
        # Advanced configuration options

        # Selective callback enabling
        enable_callbacks [
          :message_events,
          :guild_events,
          :interaction_events
        ]
        
        # Disable specific callbacks for performance
        disable_callbacks [:typing_start, :voice_state_update]
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
        doc: "Command filter module implementing AshDiscord.CommandFilter behavior for guild-scoped command filtering"
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
      auto_create_users: [
        type: :boolean,
        default: true,
        doc: "Automatically create user accounts from Discord interactions"
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
      ],
      enable_callbacks: [
        type: {:list, {:one_of, [
          :message_events, :guild_events, :role_events, :member_events, 
          :channel_events, :reaction_events, :interaction_events, :voice_events,
          :typing_events, :invite_events, :unknown_events,
          # Individual callback names for granular control
          :message_create, :message_update, :message_delete, :message_delete_bulk,
          :message_reaction_add, :message_reaction_remove, :message_reaction_remove_all,
          :guild_create, :guild_update, :guild_delete,
          :guild_role_create, :guild_role_update, :guild_role_delete,
          :guild_member_add, :guild_member_update, :guild_member_remove,
          :channel_create, :channel_update, :channel_delete,
          :interaction_create, :application_command, :ready,
          :voice_state_update, :typing_start, :invite_create, :invite_delete
        ]}},
        doc: "List of callback categories or specific callbacks to enable. Categories: :message_events, :guild_events, :role_events, :member_events, :channel_events, :reaction_events, :interaction_events, :voice_events, :typing_events, :invite_events, :unknown_events"
      ],
      disable_callbacks: [
        type: {:list, {:one_of, [
          :message_events, :guild_events, :role_events, :member_events, 
          :channel_events, :reaction_events, :interaction_events, :voice_events,
          :typing_events, :invite_events, :unknown_events,
          # Individual callback names for granular control
          :message_create, :message_update, :message_delete, :message_delete_bulk,
          :message_reaction_add, :message_reaction_remove, :message_reaction_remove_all,
          :guild_create, :guild_update, :guild_delete,
          :guild_role_create, :guild_role_update, :guild_role_delete,
          :guild_member_add, :guild_member_update, :guild_member_remove,
          :channel_create, :channel_update, :channel_delete,
          :interaction_create, :application_command, :ready,
          :voice_state_update, :typing_start, :invite_create, :invite_delete
        ]}},
        doc: "List of callback categories or specific callbacks to disable. Takes precedence over enable_callbacks for conflicts."
      ]
    ]
  }

  def ash_discord_consumer, do: @ash_discord_consumer
end