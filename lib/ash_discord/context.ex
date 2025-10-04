defmodule AshDiscord.Context do
  @moduledoc """
  Discord event context for passing through Ash operations.

  This context carries Discord-specific information like the consumer module,
  guild context, user information, and WebSocket state. It implements the
  `Ash.Scope.ToOpts` protocol to provide actor, tenant, and context information
  to Ash operations.
  """

  defstruct [
    :consumer,
    :resource,
    :guild,
    :user
  ]

  @type t :: %__MODULE__{
          consumer: module(),
          resource: Ash.Resource.t(),
          guild: Nostrum.Struct.Guild.t() | Nostrum.Snowflake.t() | nil,
          user: Nostrum.Struct.User.t() | Nostrum.Snowflake.t() | nil
        }

  defimpl Ash.Scope.ToOpts do
    @doc "Extract the actor (user) from the context"
    def get_actor(%{user: user}) when not is_nil(user), do: {:ok, user}
    def get_actor(_), do: :error

    @doc "Extract the tenant (guild) from the context"
    def get_tenant(%{guild: %Nostrum.Struct.Guild{id: guild_id}}), do: {:ok, guild_id}
    def get_tenant(%{guild: guild_id}) when not is_nil(guild_id), do: {:ok, guild_id}
    def get_tenant(_), do: :error

    @doc "Extract shared context information"
    def get_context(_context) do
      :error
    end

    @doc "Tracers are typically configured elsewhere"
    def get_tracer(_), do: :error

    @doc "Authorization should be handled by policies, not scope"
    def get_authorize?(_), do: :error
  end

  @doc """
  Extracts user information from various Discord event payloads.
  Returns the full User struct if available, otherwise returns just the user_id.
  Each payload type has an explicit pattern match.
  """
  @spec extract_user(payload :: AshDiscord.Consumer.Payload.t()) ::
          Nostrum.Struct.User.t() | Nostrum.Snowflake.t() | nil

  # message_create :: Nostrum.Struct.Message.t()
  def extract_user(%Nostrum.Struct.Message{author: author}), do: author

  # message_update :: {old_message | nil, updated_message}
  def extract_user({_old, %Nostrum.Struct.Message{author: author}}), do: author

  # message_delete :: Nostrum.Struct.Event.MessageDelete.t()
  def extract_user(%Nostrum.Struct.Event.MessageDelete{}), do: nil

  # message_delete_bulk :: Nostrum.Struct.Event.MessageDeleteBulk.t()
  def extract_user(%Nostrum.Struct.Event.MessageDeleteBulk{}), do: nil

  # interaction_create :: Nostrum.Struct.Interaction.t()
  def extract_user(%Nostrum.Struct.Interaction{user: user}), do: user

  # guild_create :: Nostrum.Struct.Guild.t()
  def extract_user(%Nostrum.Struct.Guild{}), do: nil

  # guild_update :: {old_guild, new_guild}
  def extract_user({%Nostrum.Struct.Guild{}, %Nostrum.Struct.Guild{}}), do: nil

  # guild_delete :: {old_guild, unavailable :: boolean()}
  def extract_user({%Nostrum.Struct.Guild{}, _unavailable}), do: nil

  # guild_available :: Nostrum.Struct.Guild.t() - already covered by guild_create pattern

  # guild_unavailable :: Nostrum.Struct.Guild.t() - already covered by guild_create pattern

  # guild_member_add :: {guild_id :: integer(), member}
  def extract_user({guild_id, %Nostrum.Struct.Guild.Member{user_id: user_id}})
      when is_integer(guild_id),
      do: user_id

  # guild_member_update :: {guild_id, old_member | nil, new_member}
  def extract_user({guild_id, _old, %Nostrum.Struct.Guild.Member{user_id: user_id}})
      when is_integer(guild_id),
      do: user_id

  # guild_member_remove :: {guild_id, user}
  def extract_user({guild_id, %Nostrum.Struct.User{} = user}) when is_integer(guild_id),
    do: user

  # channel_create :: Nostrum.Struct.Channel.t()
  def extract_user(%Nostrum.Struct.Channel{}), do: nil

  # channel_update :: {old_channel | nil, new_channel}
  def extract_user({_old, %Nostrum.Struct.Channel{}}), do: nil

  # channel_delete :: Nostrum.Struct.Channel.t() - already covered by channel_create pattern

  # channel_pins_update :: Nostrum.Struct.Event.ChannelPinsUpdate.t()
  def extract_user(%Nostrum.Struct.Event.ChannelPinsUpdate{}), do: nil

  # guild_role_create :: {guild_id, role}
  def extract_user({guild_id, %Nostrum.Struct.Guild.Role{}}) when is_integer(guild_id), do: nil

  # guild_role_update :: {guild_id, old_role | nil, new_role}
  def extract_user({guild_id, _old, %Nostrum.Struct.Guild.Role{}}) when is_integer(guild_id),
    do: nil

  # guild_role_delete :: {guild_id, role} - already covered by guild_role_create pattern

  # message_reaction_add :: Nostrum.Struct.Event.MessageReactionAdd.t()
  def extract_user(%Nostrum.Struct.Event.MessageReactionAdd{member: %{user: user}}), do: user
  def extract_user(%Nostrum.Struct.Event.MessageReactionAdd{user_id: user_id}), do: user_id

  # message_reaction_remove :: Nostrum.Struct.Event.MessageReactionRemove.t()
  def extract_user(%Nostrum.Struct.Event.MessageReactionRemove{user_id: user_id}), do: user_id

  # message_reaction_remove_all :: Nostrum.Struct.Event.MessageReactionRemoveAll.t()
  def extract_user(%Nostrum.Struct.Event.MessageReactionRemoveAll{}), do: nil

  # message_reaction_remove_emoji :: Nostrum.Struct.Event.MessageReactionRemoveEmoji.t()
  def extract_user(%Nostrum.Struct.Event.MessageReactionRemoveEmoji{}), do: nil

  # voice_state_update :: Nostrum.Struct.Event.VoiceState.t()
  def extract_user(%Nostrum.Struct.Event.VoiceState{user_id: user_id}), do: user_id

  # voice_ready :: Nostrum.Struct.Event.VoiceReady.t()
  def extract_user(%Nostrum.Struct.Event.VoiceReady{}), do: nil

  # voice_server_update :: Nostrum.Struct.Event.VoiceServerUpdate.t()
  def extract_user(%Nostrum.Struct.Event.VoiceServerUpdate{}), do: nil

  # voice_speaking_update :: Nostrum.Struct.Event.SpeakingUpdate.t()
  def extract_user(%Nostrum.Struct.Event.SpeakingUpdate{}), do: nil

  # voice_incoming_packet :: binary()
  def extract_user(packet) when is_binary(packet), do: nil

  # user_update :: {old_user | nil, new_user}
  def extract_user({_old, %Nostrum.Struct.User{} = new_user}), do: new_user

  # presence_update :: {guild_id, old_presence | nil, new_presence :: map()}
  def extract_user({guild_id, _old, new_presence})
      when is_integer(guild_id) and is_map(new_presence) do
    case new_presence do
      %{user: %Nostrum.Struct.User{} = user} -> user
      _ -> nil
    end
  end

  # guild_emojis_update :: {guild_id, old_emojis, new_emojis}
  def extract_user({guild_id, old, new})
      when is_integer(guild_id) and is_list(old) and is_list(new),
      do: nil

  # guild_stickers_update :: {guild_id, old_stickers, new_stickers} - same as emojis

  # thread_create :: Nostrum.Struct.Channel.t() - already covered by channel pattern

  # thread_update :: Nostrum.Struct.Channel.t() - already covered by channel pattern

  # thread_delete :: Nostrum.Struct.Channel.t() | :noop
  def extract_user(:noop), do: nil

  # thread_member_update :: Nostrum.Struct.ThreadMember.t()
  def extract_user(%Nostrum.Struct.ThreadMember{user_id: user_id}), do: user_id

  # thread_members_update :: Nostrum.Struct.Event.ThreadMembersUpdate.t()
  def extract_user(%Nostrum.Struct.Event.ThreadMembersUpdate{}), do: nil

  # thread_list_sync :: Nostrum.Struct.Event.ThreadListSync.t()
  def extract_user(%Nostrum.Struct.Event.ThreadListSync{}), do: nil

  # guild_integration_delete :: Nostrum.Struct.Event.GuildIntegrationDelete.t()
  def extract_user(%Nostrum.Struct.Event.GuildIntegrationDelete{}), do: nil

  # guild_integrations_update :: Nostrum.Struct.Event.GuildIntegrationsUpdate.t()
  def extract_user(%Nostrum.Struct.Event.GuildIntegrationsUpdate{}), do: nil

  # invite_create :: Nostrum.Struct.Event.InviteCreate.t()
  def extract_user(%Nostrum.Struct.Event.InviteCreate{inviter: inviter}), do: inviter
  def extract_user(%Nostrum.Struct.Event.InviteCreate{}), do: nil

  # invite_delete :: Nostrum.Struct.Event.InviteDelete.t()
  def extract_user(%Nostrum.Struct.Event.InviteDelete{}), do: nil

  # guild_ban_add :: Nostrum.Struct.Event.GuildBanAdd.t()
  def extract_user(%Nostrum.Struct.Event.GuildBanAdd{user: user}), do: user

  # guild_ban_remove :: Nostrum.Struct.Event.GuildBanRemove.t()
  def extract_user(%Nostrum.Struct.Event.GuildBanRemove{user: user}), do: user

  # auto_moderation_rule_create :: Nostrum.Struct.AutoModerationRule.t()
  def extract_user(%Nostrum.Struct.AutoModerationRule{}), do: nil

  # auto_moderation_rule_update :: Nostrum.Struct.AutoModerationRule.t() - same as above

  # auto_moderation_rule_delete :: Nostrum.Struct.AutoModerationRule.t() - same as above

  # auto_moderation_action_execution :: Nostrum.Struct.Event.AutoModerationRuleExecute.t()
  def extract_user(%Nostrum.Struct.Event.AutoModerationRuleExecute{user_id: user_id}), do: user_id

  # guild_audit_log_entry_create :: map()
  def extract_user(%{user_id: _} = audit_log) when is_map(audit_log), do: nil

  # ready :: Nostrum.Struct.Event.Ready.t()
  def extract_user(%Nostrum.Struct.Event.Ready{user: user}), do: user

  # resumed :: map()
  def extract_user(resumed) when is_map(resumed), do: nil

  # typing_start :: Nostrum.Struct.Event.TypingStart.t()
  def extract_user(%Nostrum.Struct.Event.TypingStart{member: %{user: user}}), do: user
  def extract_user(%Nostrum.Struct.Event.TypingStart{user_id: user_id}), do: user_id

  # message_poll_vote_add :: Nostrum.Struct.Event.PollVoteChange.t()
  def extract_user(%Nostrum.Struct.Event.PollVoteChange{user_id: user_id}), do: user_id

  # message_poll_vote_remove :: Nostrum.Struct.Event.PollVoteChange.t() - same as above

  # webhooks_update :: map()
  # guild_members_chunk :: map()
  # These are generic maps, handled by fallback

  # Default fallback
  def extract_user(_payload), do: nil

  @doc """
  Extracts guild from Discord event payloads.
  Returns the full Guild struct if available, otherwise returns just the guild_id.
  Each payload type has an explicit pattern match.
  """
  @spec extract_guild(payload :: AshDiscord.Consumer.Payload.t()) ::
          Nostrum.Struct.Guild.t() | Nostrum.Snowflake.t() | nil

  # message_create :: Nostrum.Struct.Message.t()
  def extract_guild(%Nostrum.Struct.Message{guild_id: guild_id}), do: guild_id

  # message_update :: {old_message | nil, updated_message}
  def extract_guild({_old, %Nostrum.Struct.Message{guild_id: guild_id}}), do: guild_id

  # message_delete :: Nostrum.Struct.Event.MessageDelete.t()
  def extract_guild(%Nostrum.Struct.Event.MessageDelete{guild_id: guild_id}), do: guild_id

  # message_delete_bulk :: Nostrum.Struct.Event.MessageDeleteBulk.t()
  def extract_guild(%Nostrum.Struct.Event.MessageDeleteBulk{guild_id: guild_id}), do: guild_id

  # interaction_create :: Nostrum.Struct.Interaction.t()
  def extract_guild(%Nostrum.Struct.Interaction{guild_id: guild_id}), do: guild_id

  # guild_create :: Nostrum.Struct.Guild.t()
  def extract_guild(%Nostrum.Struct.Guild{} = guild), do: guild

  # guild_update :: {old_guild, new_guild}
  def extract_guild({%Nostrum.Struct.Guild{}, %Nostrum.Struct.Guild{} = new_guild}), do: new_guild

  # guild_delete :: {old_guild, unavailable :: boolean()}
  def extract_guild({%Nostrum.Struct.Guild{} = old_guild, _unavailable}), do: old_guild

  # guild_member_add :: {guild_id :: integer(), member}
  def extract_guild({guild_id, %Nostrum.Struct.Guild.Member{}}) when is_integer(guild_id),
    do: guild_id

  # guild_member_update :: {guild_id, old_member | nil, new_member}
  def extract_guild({guild_id, _old, %Nostrum.Struct.Guild.Member{}}) when is_integer(guild_id),
    do: guild_id

  # guild_member_remove :: {guild_id, user}
  def extract_guild({guild_id, %Nostrum.Struct.User{}}) when is_integer(guild_id), do: guild_id

  # channel_create :: Nostrum.Struct.Channel.t()
  def extract_guild(%Nostrum.Struct.Channel{guild_id: guild_id}), do: guild_id

  # channel_update :: {old_channel | nil, new_channel}
  def extract_guild({_old, %Nostrum.Struct.Channel{guild_id: guild_id}}), do: guild_id

  # channel_pins_update :: Nostrum.Struct.Event.ChannelPinsUpdate.t()
  def extract_guild(%Nostrum.Struct.Event.ChannelPinsUpdate{guild_id: guild_id}), do: guild_id

  # guild_role_create :: {guild_id, role}
  def extract_guild({guild_id, %Nostrum.Struct.Guild.Role{}}) when is_integer(guild_id),
    do: guild_id

  # guild_role_update :: {guild_id, old_role | nil, new_role}
  def extract_guild({guild_id, _old, %Nostrum.Struct.Guild.Role{}}) when is_integer(guild_id),
    do: guild_id

  # message_reaction_add :: Nostrum.Struct.Event.MessageReactionAdd.t()
  def extract_guild(%Nostrum.Struct.Event.MessageReactionAdd{guild_id: guild_id}), do: guild_id

  # message_reaction_remove :: Nostrum.Struct.Event.MessageReactionRemove.t()
  def extract_guild(%Nostrum.Struct.Event.MessageReactionRemove{guild_id: guild_id}), do: guild_id

  # message_reaction_remove_all :: Nostrum.Struct.Event.MessageReactionRemoveAll.t()
  def extract_guild(%Nostrum.Struct.Event.MessageReactionRemoveAll{guild_id: guild_id}),
    do: guild_id

  # message_reaction_remove_emoji :: Nostrum.Struct.Event.MessageReactionRemoveEmoji.t()
  def extract_guild(%Nostrum.Struct.Event.MessageReactionRemoveEmoji{guild_id: guild_id}),
    do: guild_id

  # voice_state_update :: Nostrum.Struct.Event.VoiceState.t()
  def extract_guild(%Nostrum.Struct.Event.VoiceState{guild_id: guild_id}), do: guild_id

  # voice_ready :: Nostrum.Struct.Event.VoiceReady.t()
  def extract_guild(%Nostrum.Struct.Event.VoiceReady{}), do: nil

  # voice_server_update :: Nostrum.Struct.Event.VoiceServerUpdate.t()
  def extract_guild(%Nostrum.Struct.Event.VoiceServerUpdate{guild_id: guild_id}), do: guild_id

  # voice_speaking_update :: Nostrum.Struct.Event.SpeakingUpdate.t()
  def extract_guild(%Nostrum.Struct.Event.SpeakingUpdate{}), do: nil

  # voice_incoming_packet :: binary()
  def extract_guild(packet) when is_binary(packet), do: nil

  # user_update :: {old_user | nil, new_user}
  def extract_guild({_old, %Nostrum.Struct.User{}}), do: nil

  # presence_update :: {guild_id, old_presence | nil, new_presence :: map()}
  def extract_guild({guild_id, _old, new_presence})
      when is_integer(guild_id) and is_map(new_presence),
      do: guild_id

  # guild_emojis_update :: {guild_id, old_emojis, new_emojis}
  def extract_guild({guild_id, old, new})
      when is_integer(guild_id) and is_list(old) and is_list(new),
      do: guild_id

  # thread_delete :: Nostrum.Struct.Channel.t() | :noop
  def extract_guild(:noop), do: nil

  # thread_member_update :: Nostrum.Struct.ThreadMember.t()
  def extract_guild(%Nostrum.Struct.ThreadMember{guild_id: guild_id}), do: guild_id

  # thread_members_update :: Nostrum.Struct.Event.ThreadMembersUpdate.t()
  def extract_guild(%Nostrum.Struct.Event.ThreadMembersUpdate{guild_id: guild_id}), do: guild_id

  # thread_list_sync :: Nostrum.Struct.Event.ThreadListSync.t()
  def extract_guild(%Nostrum.Struct.Event.ThreadListSync{guild_id: guild_id}), do: guild_id

  # guild_integration_delete :: Nostrum.Struct.Event.GuildIntegrationDelete.t()
  def extract_guild(%Nostrum.Struct.Event.GuildIntegrationDelete{guild_id: guild_id}),
    do: guild_id

  # guild_integrations_update :: Nostrum.Struct.Event.GuildIntegrationsUpdate.t()
  def extract_guild(%Nostrum.Struct.Event.GuildIntegrationsUpdate{guild_id: guild_id}),
    do: guild_id

  # invite_create :: Nostrum.Struct.Event.InviteCreate.t()
  def extract_guild(%Nostrum.Struct.Event.InviteCreate{guild_id: guild_id}), do: guild_id

  # invite_delete :: Nostrum.Struct.Event.InviteDelete.t()
  def extract_guild(%Nostrum.Struct.Event.InviteDelete{guild_id: guild_id}), do: guild_id

  # guild_ban_add :: Nostrum.Struct.Event.GuildBanAdd.t()
  def extract_guild(%Nostrum.Struct.Event.GuildBanAdd{guild_id: guild_id}), do: guild_id

  # guild_ban_remove :: Nostrum.Struct.Event.GuildBanRemove.t()
  def extract_guild(%Nostrum.Struct.Event.GuildBanRemove{guild_id: guild_id}), do: guild_id

  # auto_moderation_rule_create :: Nostrum.Struct.AutoModerationRule.t()
  def extract_guild(%Nostrum.Struct.AutoModerationRule{guild_id: guild_id}), do: guild_id

  # auto_moderation_action_execution :: Nostrum.Struct.Event.AutoModerationRuleExecute.t()
  def extract_guild(%Nostrum.Struct.Event.AutoModerationRuleExecute{guild_id: guild_id}),
    do: guild_id

  # ready :: Nostrum.Struct.Event.Ready.t()
  def extract_guild(%Nostrum.Struct.Event.Ready{}), do: nil

  # typing_start :: Nostrum.Struct.Event.TypingStart.t()
  def extract_guild(%Nostrum.Struct.Event.TypingStart{guild_id: guild_id}), do: guild_id

  # message_poll_vote_add :: Nostrum.Struct.Event.PollVoteChange.t()
  def extract_guild(%Nostrum.Struct.Event.PollVoteChange{guild_id: guild_id}), do: guild_id

  # Default fallback
  def extract_guild(_payload), do: nil
end
