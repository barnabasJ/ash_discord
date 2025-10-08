defmodule AshDiscord.Consumer.Handler.Reaction do
  @moduledoc """
  Handler for Discord MESSAGE_REACTION events.

  Processes reaction add/remove events for messages, routing them to the configured message_reaction_resource.
  """

  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @doc """
  Handles MESSAGE_REACTION_ADD event.

  Creates or updates a message reaction record using the :from_discord action.
  """
  @spec add(
          reaction_add :: Payloads.MessageReactionAddEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def add(%Payloads.MessageReactionAddEvent{} = reaction_add, _ws_state, context) do
    case Handler.invoke_configured_action(
           :MESSAGE_REACTION_ADD,
           %{
             user_id: reaction_add.user_id,
             message_id: reaction_add.message_id,
             emoji_name: reaction_add.emoji.name,
             emoji_id: reaction_add.emoji.id
           },
           %{data: reaction_add},
           context
         ) do
      {:ok, _reaction} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Handles MESSAGE_REACTION_REMOVE event.

  Removes a specific reaction from a message by filtering on user_id, message_id, and emoji.
  """
  @spec remove(
          reaction_remove :: Payloads.MessageReactionRemoveEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def remove(%Payloads.MessageReactionRemoveEvent{} = reaction_remove, _ws_state, context) do
    # Build filter as keyword list to handle is_nil properly
    identity =
      [
        user_discord_id: reaction_remove.user_id,
        message_discord_id: reaction_remove.message_id,
        emoji_name: reaction_remove.emoji.name
      ] ++
        if is_nil(reaction_remove.emoji.id) do
          # For unicode emojis, filter where emoji_id is nil
          [emoji_id: [is_nil: true]]
        else
          # For custom emojis, match by emoji_id
          [emoji_id: reaction_remove.emoji.id]
        end

    case Handler.invoke_configured_action(
           :MESSAGE_REACTION_REMOVE,
           identity,
           %{},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Handles MESSAGE_REACTION_REMOVE_ALL event.

  Removes all reactions from a specific message.
  """
  @spec remove_all(
          reaction_remove_all :: Payloads.MessageReactionRemoveAllEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def remove_all(
        %Payloads.MessageReactionRemoveAllEvent{} = reaction_remove_all,
        _ws_state,
        context
      ) do
    case Handler.invoke_configured_action(
           :MESSAGE_REACTION_REMOVE_ALL,
           %{
             message_discord_id: reaction_remove_all.message_id,
             channel_discord_id: reaction_remove_all.channel_id
           },
           %{},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Handles MESSAGE_REACTION_REMOVE_EMOJI event.

  Removes all instances of a specific emoji from a message's reactions.
  """
  @spec remove_emoji(
          reaction_remove_emoji :: Payloads.MessageReactionRemoveEmojiEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def remove_emoji(
        %Payloads.MessageReactionRemoveEmojiEvent{} = reaction_remove_emoji,
        _ws_state,
        context
      ) do
    # Build filter as keyword list to handle is_nil properly
    identity =
      [
        message_discord_id: reaction_remove_emoji.message_id,
        channel_discord_id: reaction_remove_emoji.channel_id,
        emoji_name: reaction_remove_emoji.emoji.name
      ] ++
        if is_nil(reaction_remove_emoji.emoji.id) do
          # For unicode emojis, filter where emoji_id is nil
          [emoji_id: [is_nil: true]]
        else
          # For custom emojis, match by emoji_id
          [emoji_id: reaction_remove_emoji.emoji.id]
        end

    case Handler.invoke_configured_action(
           :MESSAGE_REACTION_REMOVE_EMOJI,
           identity,
           %{},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
