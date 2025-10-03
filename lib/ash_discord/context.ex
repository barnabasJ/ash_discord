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
    :user,
    :user_id,
    :guild_id
  ]

  @type t :: %__MODULE__{
          consumer: module(),
          resource: Ash.Resource.t(),
          user: Nostrum.Struct.User.t() | nil,
          user_id: Nostrum.Snowflake.t() | nil,
          guild_id: Nostrum.Snowflake.t() | nil
        }

  defimpl Ash.Scope.ToOpts do
    @doc "Extract the actor (user) from the context"
    def get_actor(%{user: user}) when not is_nil(user), do: {:ok, user}
    def get_actor(_), do: :error

    @doc "Extract the tenant (guild) from the context"
    def get_tenant(%{guild_id: guild_id}) when not is_nil(guild_id),
      do: {:ok, guild_id}

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
  Each payload type has an explicit pattern match.
  """
  @spec extract_user(payload :: AshDiscord.Consumer.Payload.t()) :: Nostrum.Struct.User.t() | nil

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
  def extract_user({_guild_id, %Nostrum.Struct.Guild.Member{user: user}})
      when is_integer(_guild_id),
      do: user

  # guild_member_update :: {guild_id, old_member | nil, new_member}
  def extract_user({_guild_id, _old, %Nostrum.Struct.Guild.Member{user: user}})
      when is_integer(_guild_id),
      do: user

  # guild_member_remove :: {guild_id, user}
  def extract_user({_guild_id, %Nostrum.Struct.User{} = user}) when is_integer(_guild_id),
    do: user

  # channel_create :: Nostrum.Struct.Channel.t()
  def extract_user(%Nostrum.Struct.Channel{}), do: nil

  # channel_update :: {old_channel | nil, new_channel}
  def extract_user({_old, %Nostrum.Struct.Channel{}}), do: nil

  # channel_delete :: Nostrum.Struct.Channel.t() - already covered by channel_create pattern

  # channel_pins_update :: Nostrum.Struct.Event.ChannelPinsUpdate.t()
  def extract_user(%Nostrum.Struct.Event.ChannelPinsUpdate{}), do: nil

  # guild_role_create :: {guild_id, role}
  def extract_user({_guild_id, %Nostrum.Struct.Guild.Role{}}) when is_integer(_guild_id), do: nil

  # guild_role_update :: {guild_id, old_role | nil, new_role}
  def extract_user({_guild_id, _old, %Nostrum.Struct.Guild.Role{}}) when is_integer(_guild_id),
    do: nil

  # guild_role_delete :: {guild_id, role} - already covered by guild_role_create pattern

  # message_reaction_add :: Nostrum.Struct.Event.MessageReactionAdd.t()
  def extract_user(%Nostrum.Struct.Event.MessageReactionAdd{member: %{user: user}}), do: user
  def extract_user(%Nostrum.Struct.Event.MessageReactionAdd{}), do: nil

  # message_reaction_remove :: Nostrum.Struct.Event.MessageReactionRemove.t()
  def extract_user(%Nostrum.Struct.Event.MessageReactionRemove{}), do: nil

  # message_reaction_remove_all :: Nostrum.Struct.Event.MessageReactionRemoveAll.t()
  def extract_user(%Nostrum.Struct.Event.MessageReactionRemoveAll{}), do: nil

  # message_reaction_remove_emoji :: Nostrum.Struct.Event.MessageReactionRemoveEmoji.t()
  def extract_user(%Nostrum.Struct.Event.MessageReactionRemoveEmoji{}), do: nil

  # voice_state_update :: Nostrum.Struct.Event.VoiceState.t()
  def extract_user(%Nostrum.Struct.Event.VoiceState{}), do: nil

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
  def extract_user({_guild_id, _old, new_presence})
      when is_integer(_guild_id) and is_map(new_presence) do
    case new_presence do
      %{user: %Nostrum.Struct.User{} = user} -> user
      _ -> nil
    end
  end

  # guild_emojis_update :: {guild_id, old_emojis, new_emojis}
  def extract_user({_guild_id, old, new})
      when is_integer(_guild_id) and is_list(old) and is_list(new),
      do: nil

  # guild_stickers_update :: {guild_id, old_stickers, new_stickers} - same as emojis

  # thread_create :: Nostrum.Struct.Channel.t() - already covered by channel pattern

  # thread_update :: Nostrum.Struct.Channel.t() - already covered by channel pattern

  # thread_delete :: Nostrum.Struct.Channel.t() | :noop
  def extract_user(:noop), do: nil

  # thread_member_update :: Nostrum.Struct.ThreadMember.t()
  def extract_user(%Nostrum.Struct.ThreadMember{}), do: nil

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
  def extract_user(%Nostrum.Struct.Event.AutoModerationRuleExecute{}), do: nil

  # guild_audit_log_entry_create :: map()
  def extract_user(%{user_id: _} = audit_log) when is_map(audit_log), do: nil

  # ready :: Nostrum.Struct.Event.Ready.t()
  def extract_user(%Nostrum.Struct.Event.Ready{user: user}), do: user

  # resumed :: map()
  def extract_user(resumed) when is_map(resumed), do: nil

  # typing_start :: Nostrum.Struct.Event.TypingStart.t()
  def extract_user(%Nostrum.Struct.Event.TypingStart{member: %{user: user}}), do: user
  def extract_user(%Nostrum.Struct.Event.TypingStart{}), do: nil

  # message_poll_vote_add :: Nostrum.Struct.Event.PollVoteChange.t()
  def extract_user(%Nostrum.Struct.Event.PollVoteChange{}), do: nil

  # message_poll_vote_remove :: Nostrum.Struct.Event.PollVoteChange.t() - same as above

  # webhooks_update :: map()
  # guild_members_chunk :: map()
  # These are generic maps, handled by fallback

  # Default fallback
  def extract_user(_payload), do: nil

  @doc """
  Extracts user ID from various Discord event payloads.
  Each payload type has an explicit pattern match.
  Returns user.id if user was extracted, otherwise extracts user_id directly.
  """
  @spec extract_user_id(
          payload :: AshDiscord.Consumer.Payload.t(),
          user :: Nostrum.Struct.User.t() | nil
        ) :: Nostrum.Snowflake.t() | nil

  # If we already have user, return their ID
  def extract_user_id(_payload, %Nostrum.Struct.User{id: id}), do: id

  # message_create :: Nostrum.Struct.Message.t()
  def extract_user_id(%Nostrum.Struct.Message{author: %{id: id}}, nil), do: id

  # message_update :: {old_message | nil, updated_message}
  def extract_user_id({_old, %Nostrum.Struct.Message{author: %{id: id}}}, nil), do: id

  # message_delete :: Nostrum.Struct.Event.MessageDelete.t()
  def extract_user_id(%Nostrum.Struct.Event.MessageDelete{}, nil), do: nil

  # message_delete_bulk :: Nostrum.Struct.Event.MessageDeleteBulk.t()
  def extract_user_id(%Nostrum.Struct.Event.MessageDeleteBulk{}, nil), do: nil

  # interaction_create :: Nostrum.Struct.Interaction.t()
  def extract_user_id(%Nostrum.Struct.Interaction{user: %{id: id}}, nil), do: id

  # guild_create :: Nostrum.Struct.Guild.t()
  def extract_user_id(%Nostrum.Struct.Guild{}, nil), do: nil

  # guild_update :: {old_guild, new_guild}
  def extract_user_id({%Nostrum.Struct.Guild{}, %Nostrum.Struct.Guild{}}, nil), do: nil

  # guild_delete :: {old_guild, unavailable :: boolean()}
  def extract_user_id({%Nostrum.Struct.Guild{}, _unavailable}, nil), do: nil

  # guild_member_add :: {guild_id :: integer(), member}
  def extract_user_id({_guild_id, %Nostrum.Struct.Guild.Member{user_id: user_id}}, nil)
      when is_integer(_guild_id),
      do: user_id

  # guild_member_update :: {guild_id, old_member | nil, new_member}
  def extract_user_id({_guild_id, _old, %Nostrum.Struct.Guild.Member{user_id: user_id}}, nil)
      when is_integer(_guild_id),
      do: user_id

  # guild_member_remove :: {guild_id, user}
  def extract_user_id({_guild_id, %Nostrum.Struct.User{id: id}}, nil) when is_integer(_guild_id),
    do: id

  # channel_create :: Nostrum.Struct.Channel.t()
  def extract_user_id(%Nostrum.Struct.Channel{}, nil), do: nil

  # channel_update :: {old_channel | nil, new_channel}
  def extract_user_id({_old, %Nostrum.Struct.Channel{}}, nil), do: nil

  # channel_pins_update :: Nostrum.Struct.Event.ChannelPinsUpdate.t()
  def extract_user_id(%Nostrum.Struct.Event.ChannelPinsUpdate{}, nil), do: nil

  # guild_role_create :: {guild_id, role}
  def extract_user_id({_guild_id, %Nostrum.Struct.Guild.Role{}}, nil) when is_integer(_guild_id),
    do: nil

  # guild_role_update :: {guild_id, old_role | nil, new_role}
  def extract_user_id({_guild_id, _old, %Nostrum.Struct.Guild.Role{}}, nil)
      when is_integer(_guild_id),
      do: nil

  # message_reaction_add :: Nostrum.Struct.Event.MessageReactionAdd.t()
  def extract_user_id(%Nostrum.Struct.Event.MessageReactionAdd{user_id: user_id}, nil),
    do: user_id

  # message_reaction_remove :: Nostrum.Struct.Event.MessageReactionRemove.t()
  def extract_user_id(%Nostrum.Struct.Event.MessageReactionRemove{user_id: user_id}, nil),
    do: user_id

  # message_reaction_remove_all :: Nostrum.Struct.Event.MessageReactionRemoveAll.t()
  def extract_user_id(%Nostrum.Struct.Event.MessageReactionRemoveAll{}, nil), do: nil

  # message_reaction_remove_emoji :: Nostrum.Struct.Event.MessageReactionRemoveEmoji.t()
  def extract_user_id(%Nostrum.Struct.Event.MessageReactionRemoveEmoji{}, nil), do: nil

  # voice_state_update :: Nostrum.Struct.Event.VoiceState.t()
  def extract_user_id(%Nostrum.Struct.Event.VoiceState{user_id: user_id}, nil), do: user_id

  # voice_ready :: Nostrum.Struct.Event.VoiceReady.t()
  def extract_user_id(%Nostrum.Struct.Event.VoiceReady{}, nil), do: nil

  # voice_server_update :: Nostrum.Struct.Event.VoiceServerUpdate.t()
  def extract_user_id(%Nostrum.Struct.Event.VoiceServerUpdate{}, nil), do: nil

  # voice_speaking_update :: Nostrum.Struct.Event.SpeakingUpdate.t()
  def extract_user_id(%Nostrum.Struct.Event.SpeakingUpdate{user_id: user_id}, nil), do: user_id

  # voice_incoming_packet :: binary()
  def extract_user_id(packet, nil) when is_binary(packet), do: nil

  # user_update :: {old_user | nil, new_user}
  def extract_user_id({_old, %Nostrum.Struct.User{id: id}}, nil), do: id

  # presence_update :: {guild_id, old_presence | nil, new_presence :: map()}
  def extract_user_id({_guild_id, _old, new_presence}, nil)
      when is_integer(_guild_id) and is_map(new_presence) do
    case new_presence do
      %{user: %{id: id}} -> id
      _ -> nil
    end
  end

  # guild_emojis_update :: {guild_id, old_emojis, new_emojis}
  def extract_user_id({_guild_id, old, new}, nil)
      when is_integer(_guild_id) and is_list(old) and is_list(new),
      do: nil

  # thread_delete :: Nostrum.Struct.Channel.t() | :noop
  def extract_user_id(:noop, nil), do: nil

  # thread_member_update :: Nostrum.Struct.ThreadMember.t()
  def extract_user_id(%Nostrum.Struct.ThreadMember{user_id: user_id}, nil), do: user_id

  # thread_members_update :: Nostrum.Struct.Event.ThreadMembersUpdate.t()
  def extract_user_id(%Nostrum.Struct.Event.ThreadMembersUpdate{}, nil), do: nil

  # thread_list_sync :: Nostrum.Struct.Event.ThreadListSync.t()
  def extract_user_id(%Nostrum.Struct.Event.ThreadListSync{}, nil), do: nil

  # guild_integration_delete :: Nostrum.Struct.Event.GuildIntegrationDelete.t()
  def extract_user_id(%Nostrum.Struct.Event.GuildIntegrationDelete{}, nil), do: nil

  # guild_integrations_update :: Nostrum.Struct.Event.GuildIntegrationsUpdate.t()
  def extract_user_id(%Nostrum.Struct.Event.GuildIntegrationsUpdate{}, nil), do: nil

  # invite_create :: Nostrum.Struct.Event.InviteCreate.t()
  def extract_user_id(%Nostrum.Struct.Event.InviteCreate{inviter: %{id: id}}, nil), do: id
  def extract_user_id(%Nostrum.Struct.Event.InviteCreate{}, nil), do: nil

  # invite_delete :: Nostrum.Struct.Event.InviteDelete.t()
  def extract_user_id(%Nostrum.Struct.Event.InviteDelete{}, nil), do: nil

  # guild_ban_add :: Nostrum.Struct.Event.GuildBanAdd.t()
  def extract_user_id(%Nostrum.Struct.Event.GuildBanAdd{user: %{id: id}}, nil), do: id

  # guild_ban_remove :: Nostrum.Struct.Event.GuildBanRemove.t()
  def extract_user_id(%Nostrum.Struct.Event.GuildBanRemove{user: %{id: id}}, nil), do: id

  # auto_moderation_rule_create :: Nostrum.Struct.AutoModerationRule.t()
  def extract_user_id(%Nostrum.Struct.AutoModerationRule{}, nil), do: nil

  # auto_moderation_action_execution :: Nostrum.Struct.Event.AutoModerationRuleExecute.t()
  def extract_user_id(%Nostrum.Struct.Event.AutoModerationRuleExecute{user_id: user_id}, nil),
    do: user_id

  # ready :: Nostrum.Struct.Event.Ready.t()
  def extract_user_id(%Nostrum.Struct.Event.Ready{user: %{id: id}}, nil), do: id

  # typing_start :: Nostrum.Struct.Event.TypingStart.t()
  def extract_user_id(%Nostrum.Struct.Event.TypingStart{user_id: user_id}, nil), do: user_id

  # message_poll_vote_add :: Nostrum.Struct.Event.PollVoteChange.t()
  def extract_user_id(%Nostrum.Struct.Event.PollVoteChange{user_id: user_id}, nil), do: user_id

  # Default fallback
  def extract_user_id(_payload, nil), do: nil

  @doc """
  Extracts guild ID from Discord event payloads.
  Each payload type has an explicit pattern match.
  """
  @spec extract_guild_id(payload :: AshDiscord.Consumer.Payload.t()) ::
          Nostrum.Snowflake.t() | nil

  # message_create :: Nostrum.Struct.Message.t()
  def extract_guild_id(%Nostrum.Struct.Message{guild_id: guild_id}), do: guild_id

  # message_update :: {old_message | nil, updated_message}
  def extract_guild_id({_old, %Nostrum.Struct.Message{guild_id: guild_id}}), do: guild_id

  # message_delete :: Nostrum.Struct.Event.MessageDelete.t()
  def extract_guild_id(%Nostrum.Struct.Event.MessageDelete{guild_id: guild_id}), do: guild_id

  # message_delete_bulk :: Nostrum.Struct.Event.MessageDeleteBulk.t()
  def extract_guild_id(%Nostrum.Struct.Event.MessageDeleteBulk{guild_id: guild_id}), do: guild_id

  # interaction_create :: Nostrum.Struct.Interaction.t()
  def extract_guild_id(%Nostrum.Struct.Interaction{guild_id: guild_id}), do: guild_id

  # guild_create :: Nostrum.Struct.Guild.t()
  def extract_guild_id(%Nostrum.Struct.Guild{id: guild_id}), do: guild_id

  # guild_update :: {old_guild, new_guild}
  def extract_guild_id({%Nostrum.Struct.Guild{}, %Nostrum.Struct.Guild{id: guild_id}}),
    do: guild_id

  # guild_delete :: {old_guild, unavailable :: boolean()}
  def extract_guild_id({%Nostrum.Struct.Guild{id: guild_id}, _unavailable}), do: guild_id

  # guild_member_add :: {guild_id :: integer(), member}
  def extract_guild_id({guild_id, %Nostrum.Struct.Guild.Member{}}) when is_integer(guild_id),
    do: guild_id

  # guild_member_update :: {guild_id, old_member | nil, new_member}
  def extract_guild_id({guild_id, _old, %Nostrum.Struct.Guild.Member{}})
      when is_integer(guild_id),
      do: guild_id

  # guild_member_remove :: {guild_id, user}
  def extract_guild_id({guild_id, %Nostrum.Struct.User{}}) when is_integer(guild_id), do: guild_id

  # channel_create :: Nostrum.Struct.Channel.t()
  def extract_guild_id(%Nostrum.Struct.Channel{guild_id: guild_id}), do: guild_id

  # channel_update :: {old_channel | nil, new_channel}
  def extract_guild_id({_old, %Nostrum.Struct.Channel{guild_id: guild_id}}), do: guild_id

  # channel_pins_update :: Nostrum.Struct.Event.ChannelPinsUpdate.t()
  def extract_guild_id(%Nostrum.Struct.Event.ChannelPinsUpdate{guild_id: guild_id}), do: guild_id

  # guild_role_create :: {guild_id, role}
  def extract_guild_id({guild_id, %Nostrum.Struct.Guild.Role{}}) when is_integer(guild_id),
    do: guild_id

  # guild_role_update :: {guild_id, old_role | nil, new_role}
  def extract_guild_id({guild_id, _old, %Nostrum.Struct.Guild.Role{}}) when is_integer(guild_id),
    do: guild_id

  # message_reaction_add :: Nostrum.Struct.Event.MessageReactionAdd.t()
  def extract_guild_id(%Nostrum.Struct.Event.MessageReactionAdd{guild_id: guild_id}), do: guild_id

  # message_reaction_remove :: Nostrum.Struct.Event.MessageReactionRemove.t()
  def extract_guild_id(%Nostrum.Struct.Event.MessageReactionRemove{guild_id: guild_id}),
    do: guild_id

  # message_reaction_remove_all :: Nostrum.Struct.Event.MessageReactionRemoveAll.t()
  def extract_guild_id(%Nostrum.Struct.Event.MessageReactionRemoveAll{guild_id: guild_id}),
    do: guild_id

  # message_reaction_remove_emoji :: Nostrum.Struct.Event.MessageReactionRemoveEmoji.t()
  def extract_guild_id(%Nostrum.Struct.Event.MessageReactionRemoveEmoji{guild_id: guild_id}),
    do: guild_id

  # voice_state_update :: Nostrum.Struct.Event.VoiceState.t()
  def extract_guild_id(%Nostrum.Struct.Event.VoiceState{guild_id: guild_id}), do: guild_id

  # voice_ready :: Nostrum.Struct.Event.VoiceReady.t()
  def extract_guild_id(%Nostrum.Struct.Event.VoiceReady{}), do: nil

  # voice_server_update :: Nostrum.Struct.Event.VoiceServerUpdate.t()
  def extract_guild_id(%Nostrum.Struct.Event.VoiceServerUpdate{guild_id: guild_id}), do: guild_id

  # voice_speaking_update :: Nostrum.Struct.Event.SpeakingUpdate.t()
  def extract_guild_id(%Nostrum.Struct.Event.SpeakingUpdate{}), do: nil

  # voice_incoming_packet :: binary()
  def extract_guild_id(packet) when is_binary(packet), do: nil

  # user_update :: {old_user | nil, new_user}
  def extract_guild_id({_old, %Nostrum.Struct.User{}}), do: nil

  # presence_update :: {guild_id, old_presence | nil, new_presence :: map()}
  def extract_guild_id({guild_id, _old, _new_presence})
      when is_integer(guild_id) and is_map(_new_presence),
      do: guild_id

  # guild_emojis_update :: {guild_id, old_emojis, new_emojis}
  def extract_guild_id({guild_id, old, new})
      when is_integer(guild_id) and is_list(old) and is_list(new),
      do: guild_id

  # thread_delete :: Nostrum.Struct.Channel.t() | :noop
  def extract_guild_id(:noop), do: nil

  # thread_member_update :: Nostrum.Struct.ThreadMember.t()
  def extract_guild_id(%Nostrum.Struct.ThreadMember{guild_id: guild_id}), do: guild_id

  # thread_members_update :: Nostrum.Struct.Event.ThreadMembersUpdate.t()
  def extract_guild_id(%Nostrum.Struct.Event.ThreadMembersUpdate{guild_id: guild_id}),
    do: guild_id

  # thread_list_sync :: Nostrum.Struct.Event.ThreadListSync.t()
  def extract_guild_id(%Nostrum.Struct.Event.ThreadListSync{guild_id: guild_id}), do: guild_id

  # guild_integration_delete :: Nostrum.Struct.Event.GuildIntegrationDelete.t()
  def extract_guild_id(%Nostrum.Struct.Event.GuildIntegrationDelete{guild_id: guild_id}),
    do: guild_id

  # guild_integrations_update :: Nostrum.Struct.Event.GuildIntegrationsUpdate.t()
  def extract_guild_id(%Nostrum.Struct.Event.GuildIntegrationsUpdate{guild_id: guild_id}),
    do: guild_id

  # invite_create :: Nostrum.Struct.Event.InviteCreate.t()
  def extract_guild_id(%Nostrum.Struct.Event.InviteCreate{guild_id: guild_id}), do: guild_id

  # invite_delete :: Nostrum.Struct.Event.InviteDelete.t()
  def extract_guild_id(%Nostrum.Struct.Event.InviteDelete{guild_id: guild_id}), do: guild_id

  # guild_ban_add :: Nostrum.Struct.Event.GuildBanAdd.t()
  def extract_guild_id(%Nostrum.Struct.Event.GuildBanAdd{guild_id: guild_id}), do: guild_id

  # guild_ban_remove :: Nostrum.Struct.Event.GuildBanRemove.t()
  def extract_guild_id(%Nostrum.Struct.Event.GuildBanRemove{guild_id: guild_id}), do: guild_id

  # auto_moderation_rule_create :: Nostrum.Struct.AutoModerationRule.t()
  def extract_guild_id(%Nostrum.Struct.AutoModerationRule{guild_id: guild_id}), do: guild_id

  # auto_moderation_action_execution :: Nostrum.Struct.Event.AutoModerationRuleExecute.t()
  def extract_guild_id(%Nostrum.Struct.Event.AutoModerationRuleExecute{guild_id: guild_id}),
    do: guild_id

  # ready :: Nostrum.Struct.Event.Ready.t()
  def extract_guild_id(%Nostrum.Struct.Event.Ready{}), do: nil

  # typing_start :: Nostrum.Struct.Event.TypingStart.t()
  def extract_guild_id(%Nostrum.Struct.Event.TypingStart{guild_id: guild_id}), do: guild_id

  # message_poll_vote_add :: Nostrum.Struct.Event.PollVoteChange.t()
  def extract_guild_id(%Nostrum.Struct.Event.PollVoteChange{guild_id: guild_id}), do: guild_id

  # Default fallback
  def extract_guild_id(_payload), do: nil
end
