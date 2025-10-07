defmodule AshDiscord.Resource do
  @moduledoc """
  An Ash resource extension for declaring Discord event handling capabilities.

  This extension allows Ash resources to self-declare which Discord events they handle
  and how those events map to Ash actions. Resources with this extension are automatically
  discovered by the consumer at compile time.

  ## Usage

  Add the extension to your resource and use the `ash_discord do` block:

      defmodule MyApp.Message do
        use Ash.Resource,
          extensions: [AshDiscord.Resource],
          data_layer: AshPostgres.DataLayer

        ash_discord do
          discord_entity :message
        end

        # ... rest of resource definition
      end

  ## Configuration Options

  ### Entity Shortcuts

  Use `discord_entity` to automatically map standard Discord events for an entity type:

      ash_discord do
        discord_entity :message  # Maps MESSAGE_CREATE, MESSAGE_UPDATE, MESSAGE_DELETE, etc.
      end

  ### Explicit Event Mappings

  Use the `events do` block for custom event-to-action mappings:

      ash_discord do
        events do
          on :GUILD_CREATE, :log_guild_creation
          on :USER_UPDATE, :sync_user_data
        end
      end

  ### Hybrid Approach

  Combine entity shortcuts with explicit overrides:

      ash_discord do
        discord_entity :message

        events do
          on :MESSAGE_DELETE, :soft_delete  # Override default :destroy
        end
      end

  ## Supported Entity Types

  ### Standard Entities
  - `:message`, `:guild`, `:channel`, `:user`, `:role`
  - `:guild_member`, `:message_reaction`, `:voice_state`
  - `:invite`, `:interaction`, `:presence`, `:typing_indicator`

  ### Thread Entities
  - `:thread`, `:thread_member`

  ### Guild Sub-Entities
  - `:guild_ban`, `:emoji`, `:sticker`
  - `:guild_scheduled_event`, `:guild_audit_log_entry`

  ### Moderation & Integration
  - `:auto_moderation_rule`, `:auto_moderation_rule_execute`
  - `:integration`, `:webhooks_update`

  ### Poll Entities
  - `:message_poll_vote`

  ## How It Works

  1. **At Compile Time**: The extension's transformers process your configuration
  2. **Event Expansion**: `discord_entity` is expanded to explicit event mappings
  3. **Validation**: All referenced actions are verified to exist on the resource
  4. **Registration**: Event mappings are persisted for consumer discovery
  5. **Discovery**: The consumer discovers all resources from configured domains
  6. **Routing**: Discord events are routed to the appropriate resource and action

  ## Default Action Patterns

  - CREATE events → `:from_discord`
  - UPDATE events → `:from_discord`
  - DELETE events → `:destroy`
  - REMOVE events → `:destroy`
  - ADD events → `:from_discord`

  These defaults can be overridden using explicit `events do` mappings.
  """

  use Spark.Dsl.Extension,
    sections: [AshDiscord.Dsl.Resource.ash_discord()],
    transformers: [
      AshDiscord.Resource.Transformers.ExpandEntityEvents,
      AshDiscord.Resource.Transformers.ValidateActions,
      AshDiscord.Resource.Transformers.RegisterEvents
    ]
end
