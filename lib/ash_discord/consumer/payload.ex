defmodule AshDiscord.Consumer.Payload do
  @moduledoc """
  Type definitions for Discord event payloads.

  This module consolidates all possible payload types from Nostrum events,
  providing a unified type specification for use throughout AshDiscord.
  """

  # Message events
  @type t ::
          Nostrum.Struct.Message.t()
          | {Nostrum.Struct.Message.t() | nil, Nostrum.Struct.Message.t()}
          | Nostrum.Struct.Event.MessageDelete.t()
          | Nostrum.Struct.Event.MessageDeleteBulk.t()

          # Interaction events
          | Nostrum.Struct.Interaction.t()

          # Guild events
          | Nostrum.Struct.Guild.t()
          | {Nostrum.Struct.Guild.t(), Nostrum.Struct.Guild.t()}
          | {Nostrum.Struct.Guild.t(), unavailable :: boolean()}

          # Guild member events (tuple payloads)
          | {guild_id :: integer(), Nostrum.Struct.Guild.Member.t()}
          | {guild_id :: integer(), Nostrum.Struct.Guild.Member.t() | nil,
             Nostrum.Struct.Guild.Member.t()}
          | {guild_id :: integer(), user :: Nostrum.Struct.User.t()}

          # Channel events
          | Nostrum.Struct.Channel.t()
          | {Nostrum.Struct.Channel.t() | nil, Nostrum.Struct.Channel.t()}
          | Nostrum.Struct.Event.ChannelPinsUpdate.t()

          # Role events (tuple payloads)
          | {guild_id :: integer(), Nostrum.Struct.Guild.Role.t()}
          | {guild_id :: integer(), Nostrum.Struct.Guild.Role.t() | nil,
             Nostrum.Struct.Guild.Role.t()}

          # Reaction events
          | Nostrum.Struct.Event.MessageReactionAdd.t()
          | Nostrum.Struct.Event.MessageReactionRemove.t()
          | Nostrum.Struct.Event.MessageReactionRemoveAll.t()
          | Nostrum.Struct.Event.MessageReactionRemoveEmoji.t()

          # Voice events
          | Nostrum.Struct.Event.VoiceState.t()
          | Nostrum.Struct.Event.VoiceReady.t()
          | Nostrum.Struct.Event.VoiceServerUpdate.t()
          | Nostrum.Struct.Event.SpeakingUpdate.t()
          | binary()

          # User events
          | {Nostrum.Struct.User.t() | nil, Nostrum.Struct.User.t()}

          # Presence events
          | {guild_id :: integer(), old_presence :: map() | nil, new_presence :: map()}

          # Emoji/Sticker events (tuple payloads)
          | {guild_id :: integer(), old_emojis :: [Nostrum.Struct.Emoji.t()],
             new_emojis :: [Nostrum.Struct.Emoji.t()]}
          | {guild_id :: integer(), old_stickers :: [Nostrum.Struct.Sticker.t()],
             new_stickers :: [Nostrum.Struct.Sticker.t()]}

          # Thread events
          | Nostrum.Struct.Channel.t()
          | Nostrum.Struct.ThreadMember.t()
          | Nostrum.Struct.Event.ThreadMembersUpdate.t()
          | Nostrum.Struct.Event.ThreadListSync.t()

          # Integration events
          | Nostrum.Struct.Event.GuildIntegrationDelete.t()
          | Nostrum.Struct.Event.GuildIntegrationsUpdate.t()

          # Invite events
          | Nostrum.Struct.Event.InviteCreate.t()
          | Nostrum.Struct.Event.InviteDelete.t()

          # Ban events
          | Nostrum.Struct.Event.GuildBanAdd.t()
          | Nostrum.Struct.Event.GuildBanRemove.t()

          # AutoModeration events
          | Nostrum.Struct.AutoModerationRule.t()
          | Nostrum.Struct.Event.AutoModerationActionExecution.t()

          # Audit log events
          | Nostrum.Struct.Event.GuildAuditLogEntryCreate.t()

          # Other events
          | Nostrum.Struct.Event.Ready.t()
          | Nostrum.Struct.Event.TypingStart.t()
          | Nostrum.Struct.Event.MessagePollVoteAdd.t()
          | Nostrum.Struct.Event.MessagePollVoteRemove.t()

          # Generic map payloads for events without specific structs
          | map()

          # Special cases
          | :noop
end
