defmodule AshDiscord.Dsl.Resource do
  @moduledoc """
  DSL entities and sections for Discord integration at the resource level.

  Provides the `ash_discord do` block for Ash resources to declare their
  Discord event handling capabilities.
  """

  alias AshDiscord.EventMapping
  alias Spark.Dsl.Entity
  alias Spark.Dsl.Section

  @event %Entity{
    name: :on,
    target: EventMapping,
    args: [:event, :action],
    describe: """
    Map a Discord event to an Ash action.

    Use this to explicitly declare which Discord events this resource handles
    and which actions to invoke for each event.
    """,
    examples: [
      "on :MESSAGE_CREATE, :from_discord",
      "on :MESSAGE_DELETE, :soft_delete",
      "on :GUILD_BAN_ADD, :log_ban"
    ],
    schema: [
      event: [
        type: :atom,
        required: true,
        doc: "The Discord event name (e.g., :MESSAGE_CREATE, :GUILD_UPDATE)"
      ],
      action: [
        type: :atom,
        required: true,
        doc: "The Ash action to invoke when this event occurs"
      ]
    ]
  }

  @events %Section{
    name: :events,
    describe: """
    Explicit Discord event to action mappings.

    Use this section to map specific Discord events to Ash actions.
    These mappings override any defaults provided by `discord_entity`.
    """,
    examples: [
      """
      events do
        on :MESSAGE_CREATE, :from_discord
        on :MESSAGE_UPDATE, :from_discord
        on :MESSAGE_DELETE, :soft_delete
      end
      """,
      """
      events do
        on :GUILD_BAN_ADD, :log_ban
        on :GUILD_BAN_REMOVE, :log_unban
      end
      """
    ],
    entities: [@event]
  }

  @ash_discord %Section{
    name: :ash_discord,
    describe: """
    Configure Discord integration for this resource.

    Use this section to declare what Discord events this resource handles and
    how they map to Ash actions. You can use `discord_entity` for standard
    entity types with default mappings, or use the `events do` block for
    explicit custom mappings.
    """,
    examples: [
      """
      # Simple case - entity shortcut with defaults
      ash_discord do
        discord_entity :message
      end
      """,
      """
      # Custom event mappings
      ash_discord do
        events do
          on :GUILD_CREATE, :log_guild
          on :USER_UPDATE, :log_user
        end
      end
      """,
      """
      # Hybrid - entity defaults with overrides
      ash_discord do
        discord_entity :message

        events do
          on :MESSAGE_DELETE, :soft_delete  # Override default
        end
      end
      """
    ],
    sections: [@events],
    schema: [
      discord_entity: [
        type:
          {:one_of,
           [
             # Standard entities
             :message,
             :guild,
             :channel,
             :user,
             :role,
             :guild_member,
             :message_reaction,
             :voice_state,
             :invite,
             :interaction,
             :presence,
             :typing_indicator,
             # Thread entities
             :thread,
             :thread_member,
             # Guild sub-entities
             :guild_ban,
             :emoji,
             :sticker,
             :guild_scheduled_event,
             :guild_audit_log_entry,
             # Moderation & integration
             :auto_moderation_rule,
             :auto_moderation_rule_execute,
             :integration,
             :webhooks_update,
             # Poll entities
             :message_poll_vote
           ]},
        doc: """
        The type of Discord entity this resource represents.

        When specified, automatically maps standard Discord events for this entity type
        to default actions (:from_discord for CREATE/UPDATE, :destroy for DELETE).

        Can be combined with explicit `events do` mappings to override specific events.
        """
      ]
    ]
  }

  def ash_discord, do: @ash_discord
end
