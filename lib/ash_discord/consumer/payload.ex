defmodule AshDiscord.Consumer.Payload do
  @moduledoc """
  Type definitions for Discord event payloads.

  This module defines individual named types for each Discord event payload,
  using AshDiscord TypedStruct wrappers that provide a unified type system
  for all Discord events. Each type represents the payload portion of
  the event (without the event name atom and ws_state).
  """

  alias AshDiscord.Consumer.Payloads

  # Message events
  @type message_create :: Payloads.Message.t()
  @type message_update :: Payloads.MessageUpdate.t()
  @type message_delete :: Payloads.MessageDeleteEvent.t()
  @type message_delete_bulk :: Payloads.MessageDeleteBulkEvent.t()

  # Interaction events
  @type interaction_create :: Payloads.Interaction.t()

  # Guild events
  @type guild_create :: Payloads.Guild.t()
  @type guild_update :: Payloads.GuildUpdate.t()
  @type guild_delete :: Payloads.GuildDelete.t()
  @type guild_available :: Payloads.Guild.t()
  @type guild_unavailable :: Payloads.Guild.t()

  # Guild member events
  @type guild_member_add :: Payloads.GuildMemberAdd.t()
  @type guild_member_update :: Payloads.GuildMemberUpdate.t()
  @type guild_member_remove :: Payloads.GuildMemberRemove.t()

  # Channel events
  @type channel_create :: Payloads.Channel.t()
  @type channel_update :: Payloads.ChannelUpdate.t()
  @type channel_delete :: Payloads.Channel.t()
  @type channel_pins_update :: Payloads.ChannelPinsUpdateEvent.t()

  # Role events
  @type guild_role_create :: Payloads.GuildRoleCreate.t()
  @type guild_role_update :: Payloads.GuildRoleUpdate.t()
  @type guild_role_delete :: Payloads.GuildRoleDelete.t()

  # Reaction events
  @type message_reaction_add :: Payloads.MessageReactionAddEvent.t()
  @type message_reaction_remove :: Payloads.MessageReactionRemoveEvent.t()
  @type message_reaction_remove_all :: Payloads.MessageReactionRemoveAllEvent.t()
  @type message_reaction_remove_emoji :: Payloads.MessageReactionRemoveEmojiEvent.t()

  # Voice events
  @type voice_state_update :: Payloads.VoiceStateEvent.t()
  @type voice_ready :: Payloads.VoiceReadyEvent.t()
  @type voice_server_update :: Payloads.VoiceServerUpdateEvent.t()
  @type voice_speaking_update :: Payloads.VoiceSpeakingUpdateEvent.t()
  @type voice_incoming_packet :: Payloads.VoiceIncomingPacket.t()

  # User events
  @type user_update :: Payloads.UserUpdate.t()

  # Presence events
  @type presence_update :: Payloads.PresenceUpdate.t()

  # Emoji/Sticker events
  @type guild_emojis_update :: Payloads.GuildEmojisUpdate.t()
  @type guild_stickers_update :: Payloads.GuildStickersUpdate.t()

  # Thread events
  @type thread_create :: Payloads.Channel.t()
  @type thread_update :: Payloads.Channel.t()
  @type thread_delete :: Payloads.Channel.t() | :noop
  @type thread_member_update :: Payloads.ThreadMember.t()
  @type thread_members_update :: Payloads.ThreadMembersUpdateEvent.t()
  @type thread_list_sync :: Payloads.ThreadListSyncEvent.t()

  # Integration events
  @type guild_integration_delete :: Payloads.GuildIntegrationDeleteEvent.t()
  @type guild_integrations_update :: Payloads.GuildIntegrationsUpdateEvent.t()

  # Invite events
  @type invite_create :: Payloads.InviteCreateEvent.t()
  @type invite_delete :: Payloads.InviteDeleteEvent.t()

  # Ban events
  @type guild_ban_add :: Payloads.GuildBanAddEvent.t()
  @type guild_ban_remove :: Payloads.GuildBanRemoveEvent.t()

  # AutoModeration events
  @type auto_moderation_rule_create :: Payloads.AutoModerationRule.t()
  @type auto_moderation_rule_update :: Payloads.AutoModerationRule.t()
  @type auto_moderation_rule_delete :: Payloads.AutoModerationRule.t()
  @type auto_moderation_action_execution :: Payloads.AutoModerationActionExecutionEvent.t()

  # Audit log events
  @type guild_audit_log_entry_create :: Payloads.GuildAuditLogEntryCreateEvent.t()

  # Other events
  @type ready :: Payloads.ReadyEvent.t()
  @type resumed :: Payloads.ResumedEvent.t()
  @type typing_start :: Payloads.TypingStartEvent.t()
  @type message_poll_vote_add :: Payloads.PollVoteChangeEvent.t()
  @type message_poll_vote_remove :: Payloads.PollVoteChangeEvent.t()
  @type webhooks_update :: Payloads.WebhooksUpdateEvent.t()
  @type guild_members_chunk :: Payloads.GuildMembersChunkEvent.t()

  # Union type of all payloads
  @type t ::
          message_create
          | message_update
          | message_delete
          | message_delete_bulk
          | interaction_create
          | guild_create
          | guild_update
          | guild_delete
          | guild_available
          | guild_unavailable
          | guild_member_add
          | guild_member_update
          | guild_member_remove
          | channel_create
          | channel_update
          | channel_delete
          | channel_pins_update
          | guild_role_create
          | guild_role_update
          | guild_role_delete
          | message_reaction_add
          | message_reaction_remove
          | message_reaction_remove_all
          | message_reaction_remove_emoji
          | voice_state_update
          | voice_ready
          | voice_server_update
          | voice_speaking_update
          | voice_incoming_packet
          | user_update
          | presence_update
          | guild_emojis_update
          | guild_stickers_update
          | thread_create
          | thread_update
          | thread_delete
          | thread_member_update
          | thread_members_update
          | thread_list_sync
          | guild_integration_delete
          | guild_integrations_update
          | invite_create
          | invite_delete
          | guild_ban_add
          | guild_ban_remove
          | auto_moderation_rule_create
          | auto_moderation_rule_update
          | auto_moderation_rule_delete
          | auto_moderation_action_execution
          | guild_audit_log_entry_create
          | ready
          | resumed
          | typing_start
          | message_poll_vote_add
          | message_poll_vote_remove
          | webhooks_update
          | guild_members_chunk
end
