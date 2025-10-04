defmodule AshDiscord.Consumer.EventMap do
  @moduledoc """
  Maps Discord event names to their callback handler modules and associated resource types.

  Each Discord event is mapped to a tuple containing:
  - Handler module (e.g., `AshDiscord.Consumer.Handler.Guild`)
  - Handler function name (e.g., `:create`)
  - Resource type atom (e.g., `:guild_resource`)
  - Callback name (e.g., `:handle_guild_create`)
  - Payload transformer module (e.g., `AshDiscord.Consumer.Payloads.Guild`)

  The resource type indicates which resource configuration this event relates to,
  regardless of whether that resource is actually configured in the consumer.

  The payload transformer module provides a `new/1` function to convert Nostrum structs
  to AshDiscord TypedStruct payloads.
  """

  @type event ::
          :AUTO_MODERATION_RULE_CREATE
          | :AUTO_MODERATION_RULE_DELETE
          | :AUTO_MODERATION_RULE_EXECUTE
          | :AUTO_MODERATION_RULE_UPDATE
          | :CHANNEL_CREATE
          | :CHANNEL_DELETE
          | :CHANNEL_PINS_ACK
          | :CHANNEL_PINS_UPDATE
          | :CHANNEL_UPDATE
          | :GUILD_AUDIT_LOG_ENTRY_CREATE
          | :GUILD_AVAILABLE
          | :GUILD_BAN_ADD
          | :GUILD_BAN_REMOVE
          | :GUILD_CREATE
          | :GUILD_DELETE
          | :GUILD_EMOJIS_UPDATE
          | :GUILD_INTEGRATIONS_UPDATE
          | :GUILD_MEMBER_ADD
          | :GUILD_MEMBER_REMOVE
          | :GUILD_MEMBERS_CHUNK
          | :GUILD_MEMBER_UPDATE
          | :GUILD_ROLE_CREATE
          | :GUILD_ROLE_DELETE
          | :GUILD_ROLE_UPDATE
          | :GUILD_SCHEDULED_EVENT_CREATE
          | :GUILD_SCHEDULED_EVENT_DELETE
          | :GUILD_SCHEDULED_EVENT_UPDATE
          | :GUILD_SCHEDULED_EVENT_USER_ADD
          | :GUILD_SCHEDULED_EVENT_USER_REMOVE
          | :GUILD_STICKERS_UPDATE
          | :GUILD_UNAVAILABLE
          | :GUILD_UPDATE
          | :INTEGRATION_CREATE
          | :INTEGRATION_DELETE
          | :INTEGRATION_UPDATE
          | :INTERACTION_CREATE
          | :INVITE_CREATE
          | :INVITE_DELETE
          | :MESSAGE_ACK
          | :MESSAGE_CREATE
          | :MESSAGE_DELETE
          | :MESSAGE_DELETE_BULK
          | :MESSAGE_POLL_VOTE_ADD
          | :MESSAGE_POLL_VOTE_REMOVE
          | :MESSAGE_REACTION_ADD
          | :MESSAGE_REACTION_REMOVE
          | :MESSAGE_REACTION_REMOVE_ALL
          | :MESSAGE_REACTION_REMOVE_EMOJI
          | :MESSAGE_UPDATE
          | :PRESENCE_UPDATE
          | :READY
          | :RESUMED
          | :THREAD_CREATE
          | :THREAD_DELETE
          | :THREAD_LIST_SYNC
          | :THREAD_MEMBERS_UPDATE
          | :THREAD_MEMBER_UPDATE
          | :THREAD_UPDATE
          | :TYPING_START
          | :USER_SETTINGS_UPDATE
          | :USER_UPDATE
          | :VOICE_INCOMING_PACKET
          | :VOICE_READY
          | :VOICE_SERVER_UPDATE
          | :VOICE_SPEAKING_UPDATE
          | :VOICE_STATE_UPDATE
          | :WEBHOOKS_UPDATE

  @type handler_module ::
          AshDiscord.Consumer.Handler.Channel
          | AshDiscord.Consumer.Handler.Guild
          | AshDiscord.Consumer.Handler.Interaction
          | AshDiscord.Consumer.Handler.Invite
          | AshDiscord.Consumer.Handler.Member
          | AshDiscord.Consumer.Handler.Message
          | AshDiscord.Consumer.Handler.Presence
          | AshDiscord.Consumer.Handler.Reaction
          | AshDiscord.Consumer.Handler.Ready
          | AshDiscord.Consumer.Handler.Role
          | AshDiscord.Consumer.Handler.Typing
          | AshDiscord.Consumer.Handler.User
          | AshDiscord.Consumer.Handler.Voice

  @type handler_function ::
          :add
          | :available
          | :create
          | :delete
          | :delete_bulk
          | :handle
          | :remove
          | :remove_all
          | :settings
          | :start
          | :unavailable
          | :update

  @type callback_name ::
          :handle_auto_moderation_rule_create
          | :handle_auto_moderation_rule_delete
          | :handle_auto_moderation_rule_execute
          | :handle_auto_moderation_rule_update
          | :handle_channel_create
          | :handle_channel_delete
          | :handle_channel_pins_ack
          | :handle_channel_pins_update
          | :handle_channel_update
          | :handle_guild_audit_log_entry_create
          | :handle_guild_available
          | :handle_guild_ban_add
          | :handle_guild_ban_remove
          | :handle_guild_create
          | :handle_guild_delete
          | :handle_guild_emojis_update
          | :handle_guild_integrations_update
          | :handle_guild_member_add
          | :handle_guild_member_remove
          | :handle_guild_members_chunk
          | :handle_guild_member_update
          | :handle_guild_role_create
          | :handle_guild_role_delete
          | :handle_guild_role_update
          | :handle_guild_scheduled_event_create
          | :handle_guild_scheduled_event_delete
          | :handle_guild_scheduled_event_update
          | :handle_guild_scheduled_event_user_add
          | :handle_guild_scheduled_event_user_remove
          | :handle_guild_stickers_update
          | :handle_guild_unavailable
          | :handle_guild_update
          | :handle_integration_create
          | :handle_integration_delete
          | :handle_integration_update
          | :handle_interaction_create
          | :handle_invite_create
          | :handle_invite_delete
          | :handle_message_ack
          | :handle_message_create
          | :handle_message_delete
          | :handle_message_delete_bulk
          | :handle_message_poll_vote_add
          | :handle_message_poll_vote_remove
          | :handle_message_reaction_add
          | :handle_message_reaction_remove
          | :handle_message_reaction_remove_all
          | :handle_message_reaction_remove_emoji
          | :handle_message_update
          | :handle_presence_update
          | :handle_ready
          | :handle_resumed
          | :handle_thread_create
          | :handle_thread_delete
          | :handle_thread_list_sync
          | :handle_thread_members_update
          | :handle_thread_member_update
          | :handle_thread_update
          | :handle_typing_start
          | :handle_user_settings_update
          | :handle_user_update
          | :handle_voice_incoming_packet
          | :handle_voice_ready
          | :handle_voice_server_update
          | :handle_voice_speaking_update
          | :handle_voice_state_update
          | :handle_webhooks_update

  @type resource_type ::
          :auto_moderation_rule_resource
          | :channel_resource
          | :guild_audit_log_entry_resource
          | :guild_ban_resource
          | :guild_emoji_resource
          | :guild_integration_resource
          | :guild_member_resource
          | :guild_resource
          | :guild_scheduled_event_resource
          | :guild_sticker_resource
          | :integration_resource
          | :interaction_resource
          | :invite_resource
          | :message_poll_vote_resource
          | :message_reaction_resource
          | :message_resource
          | :presence_resource
          | :ready_resource
          | :resumed_resource
          | :role_resource
          | :thread_member_resource
          | :thread_members_resource
          | :thread_resource
          | :typing_indicator_resource
          | :user_resource
          | :voice_state_resource
          | :webhooks_resource

  @type payload_module :: module()

  @doc """
  Returns the handler module, function, resource type, callback name, and payload transformer for a given Discord event.

  ## Examples

      iex> AshDiscord.Consumer.EventMap.handler_for(:GUILD_CREATE)
      {AshDiscord.Consumer.Handler.Guild, :create, :guild_resource, :handle_guild_create, AshDiscord.Consumer.Payloads.Guild}

      iex> AshDiscord.Consumer.EventMap.handler_for(:INTERACTION_CREATE)
      {AshDiscord.Consumer.Handler.Interaction, :create, :interaction_resource, :handle_interaction_create, AshDiscord.Consumer.Payloads.Interaction}
  """
  @spec handler_for(event()) ::
          {handler_module(), handler_function(), resource_type(), callback_name(),
           payload_module()}
  alias AshDiscord.Consumer.Payloads

  # Sorted alphabetically by event name for easier navigation

  # TODO: Implement auto moderation handlers
  def handler_for(:AUTO_MODERATION_RULE_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Auto.Moderation.Rule, :create, :auto_moderation_rule_resource,
       :handle_auto_moderation_rule_create, Payloads.AutoModerationRule}

  def handler_for(:AUTO_MODERATION_RULE_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Auto.Moderation.Rule, :delete, :auto_moderation_rule_resource,
       :handle_auto_moderation_rule_delete, Payloads.AutoModerationRule}

  def handler_for(:AUTO_MODERATION_RULE_EXECUTE),
    do:
      {AshDiscord.Consumer.Handler.Auto.Moderation.Rule, :execute, :auto_moderation_rule_resource,
       :handle_auto_moderation_rule_execute, Payloads.AutoModerationRuleExecute}

  def handler_for(:AUTO_MODERATION_RULE_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Auto.Moderation.Rule, :update, :auto_moderation_rule_resource,
       :handle_auto_moderation_rule_update, Payloads.AutoModerationRule}

  def handler_for(:CHANNEL_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Channel, :create, :channel_resource, :handle_channel_create,
       Payloads.Channel}

  def handler_for(:CHANNEL_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Channel, :delete, :channel_resource, :handle_channel_delete,
       Payloads.Channel}

  # TODO: Implement channel pins handlers
  def handler_for(:CHANNEL_PINS_ACK),
    do:
      {AshDiscord.Consumer.Handler.Channel.Pins, :ack, :channel_resource,
       :handle_channel_pins_ack, Payloads.ChannelPinsAck}

  def handler_for(:CHANNEL_PINS_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Channel.Pins, :update, :channel_resource,
       :handle_channel_pins_update, Payloads.ChannelPinsUpdate}

  def handler_for(:CHANNEL_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Channel, :update, :channel_resource, :handle_channel_update,
       Payloads.ChannelUpdate}

  # TODO: Implement guild audit log handler
  def handler_for(:GUILD_AUDIT_LOG_ENTRY_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Guild.Audit.Log.Entry, :create,
       :guild_audit_log_entry_resource, :handle_guild_audit_log_entry_create,
       Payloads.GuildAuditLogEntryCreate}

  def handler_for(:GUILD_AVAILABLE),
    do:
      {AshDiscord.Consumer.Handler.Guild, :available, :guild_resource, :handle_guild_available,
       Payloads.Guild}

  # TODO: Implement guild ban handlers
  def handler_for(:GUILD_BAN_ADD),
    do:
      {AshDiscord.Consumer.Handler.Guild.Ban, :add, :guild_ban_resource, :handle_guild_ban_add,
       Payloads.GuildBanAdd}

  def handler_for(:GUILD_BAN_REMOVE),
    do:
      {AshDiscord.Consumer.Handler.Guild.Ban, :remove, :guild_ban_resource,
       :handle_guild_ban_remove, Payloads.GuildBanRemove}

  def handler_for(:GUILD_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Guild, :create, :guild_resource, :handle_guild_create,
       Payloads.Guild}

  def handler_for(:GUILD_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Guild, :delete, :guild_resource, :handle_guild_delete,
       Payloads.GuildDelete}

  # TODO: Implement guild emojis handler
  def handler_for(:GUILD_EMOJIS_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Guild.Emojis, :update, :guild_emoji_resource,
       :handle_guild_emojis_update, Payloads.GuildEmojisUpdate}

  # TODO: Implement guild integrations update handler
  def handler_for(:GUILD_INTEGRATIONS_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Guild.Integrations, :update, :guild_integration_resource,
       :handle_guild_integrations_update, Payloads.GuildIntegrationsUpdate}

  def handler_for(:GUILD_MEMBER_ADD),
    do:
      {AshDiscord.Consumer.Handler.Member, :add, :guild_member_resource, :handle_guild_member_add,
       Payloads.GuildMemberAdd}

  def handler_for(:GUILD_MEMBER_REMOVE),
    do:
      {AshDiscord.Consumer.Handler.Member, :remove, :guild_member_resource,
       :handle_guild_member_remove, Payloads.GuildMemberRemove}

  def handler_for(:GUILD_MEMBER_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Member, :update, :guild_member_resource,
       :handle_guild_member_update, Payloads.GuildMemberUpdate}

  # TODO: Implement guild members chunk handler
  def handler_for(:GUILD_MEMBERS_CHUNK),
    do:
      {AshDiscord.Consumer.Handler.Guild.Members, :chunk, :guild_member_resource,
       :handle_guild_members_chunk, Payloads.GuildMembersChunk}

  def handler_for(:GUILD_ROLE_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Guild.Role, :create, :role_resource, :handle_guild_role_create,
       Payloads.GuildRoleCreate}

  def handler_for(:GUILD_ROLE_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Guild.Role, :delete, :role_resource, :handle_guild_role_delete,
       Payloads.GuildRoleDelete}

  def handler_for(:GUILD_ROLE_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Guild.Role, :update, :role_resource, :handle_guild_role_update,
       Payloads.GuildRoleUpdate}

  # TODO: Implement guild scheduled event handlers
  def handler_for(:GUILD_SCHEDULED_EVENT_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Guild.ScheduledEvent, :create, :guild_scheduled_event_resource,
       :handle_guild_scheduled_event_create, Payloads.GuildScheduledEvent}

  def handler_for(:GUILD_SCHEDULED_EVENT_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Guild.ScheduledEvent, :delete, :guild_scheduled_event_resource,
       :handle_guild_scheduled_event_delete, Payloads.GuildScheduledEvent}

  def handler_for(:GUILD_SCHEDULED_EVENT_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Guild.ScheduledEvent, :update, :guild_scheduled_event_resource,
       :handle_guild_scheduled_event_update, Payloads.GuildScheduledEvent}

  def handler_for(:GUILD_SCHEDULED_EVENT_USER_ADD),
    do:
      {AshDiscord.Consumer.Handler.Guild.ScheduledEvent, :user_add,
       :guild_scheduled_event_resource, :handle_guild_scheduled_event_user_add,
       Payloads.GuildScheduledEventUserAdd}

  def handler_for(:GUILD_SCHEDULED_EVENT_USER_REMOVE),
    do:
      {AshDiscord.Consumer.Handler.Guild.ScheduledEvent, :user_remove,
       :guild_scheduled_event_resource, :handle_guild_scheduled_event_user_remove,
       Payloads.GuildScheduledEventUserRemove}

  # TODO: Implement guild stickers handler
  def handler_for(:GUILD_STICKERS_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Guild.Stickers, :update, :guild_sticker_resource,
       :handle_guild_stickers_update, Payloads.GuildStickersUpdate}

  def handler_for(:GUILD_UNAVAILABLE),
    do:
      {AshDiscord.Consumer.Handler.Guild, :unavailable, :guild_resource,
       :handle_guild_unavailable, Payloads.Guild}

  def handler_for(:GUILD_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Guild, :update, :guild_resource, :handle_guild_update,
       Payloads.GuildUpdate}

  def handler_for(:INTERACTION_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Interaction, :create, :interaction_resource,
       :handle_interaction_create, Payloads.Interaction}

  # TODO: Implement integration handlers
  def handler_for(:INTEGRATION_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Integration, :create, :integration_resource,
       :handle_integration_create, Payloads.Integration}

  def handler_for(:INTEGRATION_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Integration, :delete, :integration_resource,
       :handle_integration_delete, Payloads.IntegrationDelete}

  def handler_for(:INTEGRATION_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Integration, :update, :integration_resource,
       :handle_integration_update, Payloads.Integration}

  def handler_for(:INVITE_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Invite, :create, :invite_resource, :handle_invite_create,
       Payloads.InviteCreateEvent}

  def handler_for(:INVITE_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Invite, :delete, :invite_resource, :handle_invite_delete,
       Payloads.InviteDeleteEvent}

  # TODO: Implement message ack handler
  def handler_for(:MESSAGE_ACK),
    do:
      {AshDiscord.Consumer.Handler.Message, :ack, :message_resource, :handle_message_ack,
       Payloads.MessageAck}

  def handler_for(:MESSAGE_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Message, :create, :message_resource, :handle_message_create,
       Payloads.Message}

  def handler_for(:MESSAGE_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Message, :delete, :message_resource, :handle_message_delete,
       Payloads.MessageDeleteEvent}

  def handler_for(:MESSAGE_DELETE_BULK),
    do:
      {AshDiscord.Consumer.Handler.Message, :delete_bulk, :message_resource,
       :handle_message_delete_bulk, Payloads.MessageDeleteBulkEvent}

  # TODO: Implement message poll vote handlers
  def handler_for(:MESSAGE_POLL_VOTE_ADD),
    do:
      {AshDiscord.Consumer.Handler.Message.Poll.Vote, :add, :message_poll_vote_resource,
       :handle_message_poll_vote_add, Payloads.MessagePollVoteAdd}

  def handler_for(:MESSAGE_POLL_VOTE_REMOVE),
    do:
      {AshDiscord.Consumer.Handler.Message.Poll.Vote, :remove, :message_poll_vote_resource,
       :handle_message_poll_vote_remove, Payloads.MessagePollVoteRemove}

  def handler_for(:MESSAGE_REACTION_ADD),
    do:
      {AshDiscord.Consumer.Handler.Reaction, :add, :message_reaction_resource,
       :handle_message_reaction_add, Payloads.MessageReactionAddEvent}

  def handler_for(:MESSAGE_REACTION_REMOVE),
    do:
      {AshDiscord.Consumer.Handler.Reaction, :remove, :message_reaction_resource,
       :handle_message_reaction_remove, Payloads.MessageReactionRemoveEvent}

  def handler_for(:MESSAGE_REACTION_REMOVE_ALL),
    do:
      {AshDiscord.Consumer.Handler.Reaction, :remove_all, :message_reaction_resource,
       :handle_message_reaction_remove_all, Payloads.MessageReactionRemoveAllEvent}

  # TODO: Implement message reaction remove emoji handler
  def handler_for(:MESSAGE_REACTION_REMOVE_EMOJI),
    do:
      {AshDiscord.Consumer.Handler.Reaction, :remove_emoji, :message_reaction_resource,
       :handle_message_reaction_remove_emoji, Payloads.MessageReactionRemoveEmoji}

  def handler_for(:MESSAGE_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Message, :update, :message_resource, :handle_message_update,
       Payloads.MessageUpdate}

  def handler_for(:PRESENCE_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Presence, :update, :presence_resource, :handle_presence_update,
       Payloads.PresenceUpdate}

  def handler_for(:READY),
    do:
      {AshDiscord.Consumer.Handler.Ready, :handle, :ready_resource, :handle_ready,
       Payloads.ReadyEvent}

  # TODO: Implement resumed handler
  def handler_for(:RESUMED),
    do:
      {AshDiscord.Consumer.Handler.Resumed, :handle, :resumed_resource, :handle_resumed,
       Payloads.Resumed}

  # TODO: Implement thread handlers
  def handler_for(:THREAD_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Thread, :create, :thread_resource, :handle_thread_create,
       Payloads.Thread}

  def handler_for(:THREAD_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Thread, :delete, :thread_resource, :handle_thread_delete,
       Payloads.ThreadDelete}

  def handler_for(:THREAD_LIST_SYNC),
    do:
      {AshDiscord.Consumer.Handler.Thread, :list_sync, :thread_resource, :handle_thread_list_sync,
       Payloads.ThreadListSync}

  def handler_for(:THREAD_MEMBER_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Thread.Member, :update, :thread_member_resource,
       :handle_thread_member_update, Payloads.ThreadMember}

  def handler_for(:THREAD_MEMBERS_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Thread.Members, :update, :thread_members_resource,
       :handle_thread_members_update, Payloads.ThreadMembersUpdate}

  def handler_for(:THREAD_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Thread, :update, :thread_resource, :handle_thread_update,
       Payloads.ThreadUpdate}

  def handler_for(:TYPING_START),
    do:
      {AshDiscord.Consumer.Handler.Typing, :start, :typing_indicator_resource,
       :handle_typing_start, Payloads.TypingStartEvent}

  def handler_for(:USER_SETTINGS_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.User, :settings, :user_resource, :handle_user_settings_update,
       Payloads.User}

  def handler_for(:USER_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.User, :update, :user_resource, :handle_user_update,
       Payloads.UserUpdate}

  # TODO: Implement voice handlers (already have voice.ex but missing these functions)
  def handler_for(:VOICE_INCOMING_PACKET),
    do:
      {AshDiscord.Consumer.Handler.Voice, :incoming, :voice_state_resource,
       :handle_voice_incoming_packet, Payloads.VoiceIncomingPacket}

  def handler_for(:VOICE_READY),
    do:
      {AshDiscord.Consumer.Handler.Voice, :ready, :voice_state_resource, :handle_voice_ready,
       Payloads.VoiceReady}

  def handler_for(:VOICE_SERVER_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Voice, :server, :voice_state_resource,
       :handle_voice_server_update, Payloads.VoiceServerUpdate}

  def handler_for(:VOICE_SPEAKING_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Voice, :speaking, :voice_state_resource,
       :handle_voice_speaking_update, Payloads.VoiceSpeakingUpdate}

  def handler_for(:VOICE_STATE_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Voice, :update, :voice_state_resource,
       :handle_voice_state_update, Payloads.VoiceStateEvent}

  # TODO: Implement webhooks handler
  def handler_for(:WEBHOOKS_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Webhooks, :update, :webhooks_resource, :handle_webhooks_update,
       Payloads.WebhooksUpdate}
end
