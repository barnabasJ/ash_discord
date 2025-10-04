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
          :CHANNEL_CREATE
          | :CHANNEL_DELETE
          | :CHANNEL_UPDATE
          | :GUILD_AVAILABLE
          | :GUILD_CREATE
          | :GUILD_DELETE
          | :GUILD_MEMBER_ADD
          | :GUILD_MEMBER_REMOVE
          | :GUILD_MEMBER_UPDATE
          | :GUILD_ROLE_CREATE
          | :GUILD_ROLE_DELETE
          | :GUILD_ROLE_UPDATE
          | :GUILD_UNAVAILABLE
          | :GUILD_UPDATE
          | :INTERACTION_CREATE
          | :INVITE_CREATE
          | :INVITE_DELETE
          | :MESSAGE_CREATE
          | :MESSAGE_DELETE
          | :MESSAGE_DELETE_BULK
          | :MESSAGE_REACTION_ADD
          | :MESSAGE_REACTION_REMOVE
          | :MESSAGE_REACTION_REMOVE_ALL
          | :MESSAGE_UPDATE
          | :PRESENCE_UPDATE
          | :READY
          | :TYPING_START
          | :USER_SETTINGS_UPDATE
          | :USER_UPDATE
          | :VOICE_STATE_UPDATE

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
          :handle_channel_create
          | :handle_channel_delete
          | :handle_channel_update
          | :handle_guild_available
          | :handle_guild_create
          | :handle_guild_delete
          | :handle_guild_member_add
          | :handle_guild_member_remove
          | :handle_guild_member_update
          | :handle_guild_role_create
          | :handle_guild_role_delete
          | :handle_guild_role_update
          | :handle_guild_unavailable
          | :handle_guild_update
          | :handle_interaction_create
          | :handle_invite_create
          | :handle_invite_delete
          | :handle_message_create
          | :handle_message_delete
          | :handle_message_delete_bulk
          | :handle_message_reaction_add
          | :handle_message_reaction_remove
          | :handle_message_reaction_remove_all
          | :handle_message_update
          | :handle_presence_update
          | :handle_ready
          | :handle_typing_start
          | :handle_user_settings_update
          | :handle_user_update
          | :handle_voice_state_update

  @type resource_type ::
          :channel_resource
          | :guild_member_resource
          | :guild_resource
          | :interaction_resource
          | :invite_resource
          | :message_reaction_resource
          | :message_resource
          | :presence_resource
          | :ready_resource
          | :role_resource
          | :typing_indicator_resource
          | :user_resource
          | :voice_state_resource

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
          {handler_module(), handler_function(), resource_type(), callback_name(), payload_module()}
  alias AshDiscord.Consumer.Payloads

  def handler_for(:CHANNEL_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Channel, :create, :channel_resource, :handle_channel_create,
       Payloads.Channel}

  def handler_for(:CHANNEL_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Channel, :delete, :channel_resource, :handle_channel_delete,
       Payloads.Channel}

  def handler_for(:CHANNEL_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Channel, :update, :channel_resource, :handle_channel_update,
       Payloads.ChannelUpdate}

  def handler_for(:GUILD_AVAILABLE),
    do:
      {AshDiscord.Consumer.Handler.Guild, :available, :guild_resource, :handle_guild_available,
       Payloads.Guild}

  def handler_for(:GUILD_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Guild, :create, :guild_resource, :handle_guild_create,
       Payloads.Guild}

  def handler_for(:GUILD_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Guild, :delete, :guild_resource, :handle_guild_delete,
       Payloads.GuildDelete}

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

  def handler_for(:GUILD_ROLE_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Role, :create, :role_resource, :handle_guild_role_create,
       Payloads.GuildRoleCreate}

  def handler_for(:GUILD_ROLE_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Role, :delete, :role_resource, :handle_guild_role_delete,
       Payloads.GuildRoleDelete}

  def handler_for(:GUILD_ROLE_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Role, :update, :role_resource, :handle_guild_role_update,
       Payloads.GuildRoleUpdate}

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

  def handler_for(:INVITE_CREATE),
    do:
      {AshDiscord.Consumer.Handler.Invite, :create, :invite_resource, :handle_invite_create,
       Payloads.InviteCreateEvent}

  def handler_for(:INVITE_DELETE),
    do:
      {AshDiscord.Consumer.Handler.Invite, :delete, :invite_resource, :handle_invite_delete,
       Payloads.InviteDeleteEvent}

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

  def handler_for(:VOICE_STATE_UPDATE),
    do:
      {AshDiscord.Consumer.Handler.Voice, :update, :voice_state_resource,
       :handle_voice_state_update, Payloads.VoiceStateEvent}
end
