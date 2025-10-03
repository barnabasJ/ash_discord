defmodule AshDiscord.Consumer.Payload do
  @moduledoc """
  Type definitions for Discord event payloads.

  This module defines individual named types for each Discord event payload,
  following Nostrum's pattern. Each type represents the payload portion of
  the event (without the event name atom and ws_state).
  """

  # Message events
  @type message_create :: Nostrum.Struct.Message.t()

  @type message_update ::
          {old_message :: Nostrum.Struct.Message.t() | nil,
           updated_message :: Nostrum.Struct.Message.t()}

  @type message_delete :: Nostrum.Struct.Event.MessageDelete.t()

  @type message_delete_bulk :: Nostrum.Struct.Event.MessageDeleteBulk.t()

  # Interaction events
  @type interaction_create :: Nostrum.Struct.Interaction.t()

  # Guild events
  @type guild_create :: Nostrum.Struct.Guild.t()

  @type guild_update ::
          {old_guild :: Nostrum.Struct.Guild.t(), new_guild :: Nostrum.Struct.Guild.t()}

  @type guild_delete ::
          {old_guild :: Nostrum.Struct.Guild.t(), unavailable :: boolean()}

  @type guild_available :: Nostrum.Struct.Guild.t()

  @type guild_unavailable :: Nostrum.Struct.Guild.t()

  # Guild member events
  @type guild_member_add ::
          {guild_id :: integer(), member :: Nostrum.Struct.Guild.Member.t()}

  @type guild_member_update ::
          {guild_id :: integer(), old_member :: Nostrum.Struct.Guild.Member.t() | nil,
           new_member :: Nostrum.Struct.Guild.Member.t()}

  @type guild_member_remove ::
          {guild_id :: integer(), user :: Nostrum.Struct.User.t()}

  # Channel events
  @type channel_create :: Nostrum.Struct.Channel.t()

  @type channel_update ::
          {old_channel :: Nostrum.Struct.Channel.t() | nil,
           new_channel :: Nostrum.Struct.Channel.t()}

  @type channel_delete :: Nostrum.Struct.Channel.t()

  @type channel_pins_update :: Nostrum.Struct.Event.ChannelPinsUpdate.t()

  # Role events
  @type guild_role_create ::
          {guild_id :: integer(), role :: Nostrum.Struct.Guild.Role.t()}

  @type guild_role_update ::
          {guild_id :: integer(), old_role :: Nostrum.Struct.Guild.Role.t() | nil,
           new_role :: Nostrum.Struct.Guild.Role.t()}

  @type guild_role_delete ::
          {guild_id :: integer(), role :: Nostrum.Struct.Guild.Role.t()}

  # Reaction events
  @type message_reaction_add :: Nostrum.Struct.Event.MessageReactionAdd.t()

  @type message_reaction_remove :: Nostrum.Struct.Event.MessageReactionRemove.t()

  @type message_reaction_remove_all :: Nostrum.Struct.Event.MessageReactionRemoveAll.t()

  @type message_reaction_remove_emoji :: Nostrum.Struct.Event.MessageReactionRemoveEmoji.t()

  # Voice events
  @type voice_state_update :: Nostrum.Struct.Event.VoiceState.t()

  @type voice_ready :: Nostrum.Struct.Event.VoiceReady.t()

  @type voice_server_update :: Nostrum.Struct.Event.VoiceServerUpdate.t()

  @type voice_speaking_update :: Nostrum.Struct.Event.SpeakingUpdate.t()

  @type voice_incoming_packet :: binary()

  # User events
  @type user_update ::
          {old_user :: Nostrum.Struct.User.t() | nil, new_user :: Nostrum.Struct.User.t()}

  # Presence events
  @type presence_update ::
          {guild_id :: integer(), old_presence :: map() | nil, new_presence :: map()}

  # Emoji/Sticker events
  @type guild_emojis_update ::
          {guild_id :: integer(), old_emojis :: [Nostrum.Struct.Emoji.t()],
           new_emojis :: [Nostrum.Struct.Emoji.t()]}

  @type guild_stickers_update ::
          {guild_id :: integer(), old_stickers :: [Nostrum.Struct.Sticker.t()],
           new_stickers :: [Nostrum.Struct.Sticker.t()]}

  # Thread events
  @type thread_create :: Nostrum.Struct.Channel.t()

  @type thread_update :: Nostrum.Struct.Channel.t()

  @type thread_delete :: Nostrum.Struct.Channel.t() | :noop

  @type thread_member_update :: Nostrum.Struct.ThreadMember.t()

  @type thread_members_update :: Nostrum.Struct.Event.ThreadMembersUpdate.t()

  @type thread_list_sync :: Nostrum.Struct.Event.ThreadListSync.t()

  # Integration events
  @type guild_integration_delete :: Nostrum.Struct.Event.GuildIntegrationDelete.t()

  @type guild_integrations_update :: Nostrum.Struct.Event.GuildIntegrationsUpdate.t()

  # Invite events
  @type invite_create :: Nostrum.Struct.Event.InviteCreate.t()

  @type invite_delete :: Nostrum.Struct.Event.InviteDelete.t()

  # Ban events
  @type guild_ban_add :: Nostrum.Struct.Event.GuildBanAdd.t()

  @type guild_ban_remove :: Nostrum.Struct.Event.GuildBanRemove.t()

  # AutoModeration events
  @type auto_moderation_rule_create :: Nostrum.Struct.AutoModerationRule.t()

  @type auto_moderation_rule_update :: Nostrum.Struct.AutoModerationRule.t()

  @type auto_moderation_rule_delete :: Nostrum.Struct.AutoModerationRule.t()

  @type auto_moderation_action_execution :: Nostrum.Struct.Event.AutoModerationRuleExecute.t()

  # Audit log events (not exposed as event struct in Nostrum)
  @type guild_audit_log_entry_create :: map()

  # Other events
  @type ready :: Nostrum.Struct.Event.Ready.t()

  @type resumed :: map()

  @type typing_start :: Nostrum.Struct.Event.TypingStart.t()

  @type message_poll_vote_add :: Nostrum.Struct.Event.PollVoteChange.t()

  @type message_poll_vote_remove :: Nostrum.Struct.Event.PollVoteChange.t()

  @type webhooks_update :: map()

  @type guild_members_chunk :: map()

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
