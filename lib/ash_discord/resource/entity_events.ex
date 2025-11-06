defmodule AshDiscord.Resource.EntityEvents do
  @moduledoc """
  Maps Discord entity types to their associated events with default actions.

  This module provides the default event→action mappings for each Discord entity type.
  These defaults can be overridden using explicit `events do` declarations in resources.

  ## Standard Action Patterns

  - CREATE events → `:from_discord`
  - UPDATE events → `:from_discord`
  - DELETE events → `:destroy`
  - REMOVE events → `:destroy`
  - ADD events → `:from_discord`
  """

  @type entity_type :: atom()
  @type event :: atom()
  @type action :: atom()
  @type event_mapping :: {event(), action()}

  @doc """
  Returns the default event mappings for a given entity type.

  Returns `[]` if the entity type is not recognized.

  ## Examples

      iex> AshDiscord.Resource.EntityEvents.events_for(:message)
      [
        {:MESSAGE_CREATE, :from_discord},
        {:MESSAGE_UPDATE, :from_discord},
        {:MESSAGE_DELETE, :destroy},
        {:MESSAGE_DELETE_BULK, :destroy}
      ]
  """
  @spec events_for(entity_type()) :: [event_mapping()]
  def events_for(entity_type)

  # Standard entities
  def events_for(:message) do
    [
      {:MESSAGE_CREATE, :from_discord},
      {:MESSAGE_UPDATE, :from_discord},
      {:MESSAGE_DELETE, :destroy},
      {:MESSAGE_DELETE_BULK, :destroy}
    ]
  end

  def events_for(:guild) do
    [
      {:GUILD_CREATE, :from_discord},
      {:GUILD_UPDATE, :from_discord},
      {:GUILD_DELETE, :destroy},
      {:GUILD_AVAILABLE, :from_discord},
      {:GUILD_UNAVAILABLE, :from_discord}
    ]
  end

  def events_for(:channel) do
    [
      {:CHANNEL_CREATE, :from_discord},
      {:CHANNEL_UPDATE, :from_discord},
      {:CHANNEL_DELETE, :destroy}
      # CHANNEL_PINS_UPDATE removed - handle with separate ChannelPinsUpdate resource
    ]
  end

  def events_for(:user) do
    [
      {:USER_UPDATE, :from_discord}
    ]
  end

  def events_for(:role) do
    [
      {:GUILD_ROLE_CREATE, :from_discord},
      {:GUILD_ROLE_UPDATE, :from_discord},
      {:GUILD_ROLE_DELETE, :destroy}
    ]
  end

  def events_for(:guild_member) do
    [
      {:GUILD_MEMBER_ADD, :from_discord},
      {:GUILD_MEMBER_UPDATE, :from_discord},
      {:GUILD_MEMBER_REMOVE, :destroy},
      {:GUILD_MEMBERS_CHUNK, :from_discord}
    ]
  end

  def events_for(:message_reaction) do
    [
      {:MESSAGE_REACTION_ADD, :from_discord},
      {:MESSAGE_REACTION_REMOVE, :destroy},
      {:MESSAGE_REACTION_REMOVE_ALL, :destroy},
      {:MESSAGE_REACTION_REMOVE_EMOJI, :destroy}
    ]
  end

  def events_for(:voice_state) do
    [
      {:VOICE_STATE_UPDATE, :from_discord},
      {:VOICE_SERVER_UPDATE, :from_discord},
      {:VOICE_READY, :from_discord},
      {:VOICE_SPEAKING_UPDATE, :from_discord},
      {:VOICE_INCOMING_PACKET, :from_discord}
    ]
  end

  def events_for(:invite) do
    [
      {:INVITE_CREATE, :from_discord},
      {:INVITE_DELETE, :destroy}
    ]
  end

  def events_for(:interaction) do
    [
      {:INTERACTION_CREATE, :from_discord}
    ]
  end

  def events_for(:presence) do
    [
      {:PRESENCE_UPDATE, :from_discord}
    ]
  end

  def events_for(:typing_indicator) do
    [
      {:TYPING_START, :from_discord}
    ]
  end

  # Thread entities
  def events_for(:thread) do
    [
      {:THREAD_CREATE, :from_discord},
      {:THREAD_UPDATE, :from_discord},
      {:THREAD_DELETE, :destroy}
      # THREAD_LIST_SYNC removed - handle with separate ThreadListSync resource
    ]
  end

  def events_for(:thread_member) do
    [
      {:THREAD_MEMBER_UPDATE, :from_discord}
      # THREAD_MEMBERS_UPDATE removed - handle with separate ThreadMembersUpdate resource
    ]
  end

  # Guild sub-entities
  def events_for(:guild_ban) do
    [
      {:GUILD_BAN_ADD, :from_discord},
      {:GUILD_BAN_REMOVE, :destroy}
    ]
  end

  def events_for(:emoji) do
    [
      {:GUILD_EMOJIS_UPDATE, :from_discord}
    ]
  end

  def events_for(:sticker) do
    [
      {:GUILD_STICKERS_UPDATE, :from_discord}
    ]
  end

  def events_for(:guild_scheduled_event) do
    [
      {:GUILD_SCHEDULED_EVENT_CREATE, :from_discord},
      {:GUILD_SCHEDULED_EVENT_UPDATE, :from_discord},
      {:GUILD_SCHEDULED_EVENT_DELETE, :destroy}
      # GUILD_SCHEDULED_EVENT_USER_ADD/REMOVE removed - handle with separate GuildScheduledEventUser resource
    ]
  end

  def events_for(:guild_audit_log_entry) do
    [
      {:GUILD_AUDIT_LOG_ENTRY_CREATE, :from_discord}
    ]
  end

  # Moderation & integration
  def events_for(:auto_moderation_rule) do
    [
      {:AUTO_MODERATION_RULE_CREATE, :from_discord},
      {:AUTO_MODERATION_RULE_UPDATE, :from_discord},
      {:AUTO_MODERATION_RULE_DELETE, :destroy}
    ]
  end

  def events_for(:auto_moderation_rule_execute) do
    [
      {:AUTO_MODERATION_RULE_EXECUTE, :from_discord}
    ]
  end

  def events_for(:integration) do
    [
      {:INTEGRATION_CREATE, :from_discord},
      {:INTEGRATION_UPDATE, :from_discord},
      {:INTEGRATION_DELETE, :destroy},
      {:GUILD_INTEGRATIONS_UPDATE, :from_discord}
    ]
  end

  def events_for(:webhooks_update) do
    [
      {:WEBHOOKS_UPDATE, :from_discord}
    ]
  end

  # Poll entities
  def events_for(:message_poll_vote) do
    [
      {:MESSAGE_POLL_VOTE_ADD, :from_discord},
      {:MESSAGE_POLL_VOTE_REMOVE, :destroy}
    ]
  end

  # Unknown entity type
  def events_for(_), do: []

  @doc """
  Returns a list of all supported entity types.

  ## Examples

      iex> :message in AshDiscord.Resource.EntityEvents.entity_types()
      true
  """
  @spec entity_types() :: [entity_type()]
  def entity_types do
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
    ]
  end
end
