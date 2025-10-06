defmodule AshDiscord.Consumer.Handler.Reaction do
  @moduledoc """
  Handler for Discord MESSAGE_REACTION events.

  Processes reaction add/remove events for messages, routing them to the configured message_reaction_resource.
  """

  require Ash.Query
  require Logger

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
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{
      data: reaction_add
    })
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _reaction_record} -> :ok
      {:error, _error} = error -> error
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
    user_id = reaction_remove.user_id
    message_id = reaction_remove.message_id
    emoji_name = reaction_remove.emoji.name
    emoji_id = reaction_remove.emoji.id

    # Build query to find the specific reaction
    query =
      context.resource
      |> Ash.Query.filter(
        user_id == ^user_id and message_id == ^message_id and emoji_name == ^emoji_name
      )
      |> then(fn q ->
        if is_nil(emoji_id) do
          # For unicode emojis, emoji_id should be nil
          Ash.Query.filter(q, is_nil(emoji_id))
        else
          # For custom emojis, match by emoji_id
          Ash.Query.filter(q, emoji_id == ^emoji_id)
        end
      end)

    case Ash.bulk_destroy(query, :destroy, %{},
           context: %{
             private: %{ash_discord?: true},
             shared: %{private: %{ash_discord?: true}}
           }
         ) do
      %Ash.BulkResult{status: :success} ->
        :ok

      result ->
        {:error, result}
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
    message_id = reaction_remove_all.message_id
    channel_id = reaction_remove_all.channel_id

    # Remove all reactions for this message
    query =
      context.resource
      |> Ash.Query.filter(message_id == ^message_id and channel_id == ^channel_id)

    case Ash.bulk_destroy(query, :destroy, %{},
           context: %{
             private: %{ash_discord?: true},
             shared: %{private: %{ash_discord?: true}}
           }
         ) do
      %Ash.BulkResult{status: :success} ->
        :ok

      result ->
        {:error, result}
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
    message_id = reaction_remove_emoji.message_id
    channel_id = reaction_remove_emoji.channel_id
    emoji_name = reaction_remove_emoji.emoji.name
    emoji_id = reaction_remove_emoji.emoji.id

    # Remove all reactions with this emoji from the message
    query =
      context.resource
      |> Ash.Query.filter(
        message_id == ^message_id and channel_id == ^channel_id and emoji_name == ^emoji_name
      )
      |> then(fn q ->
        if is_nil(emoji_id) do
          # For unicode emojis, emoji_id should be nil
          Ash.Query.filter(q, is_nil(emoji_id))
        else
          # For custom emojis, match by emoji_id
          Ash.Query.filter(q, emoji_id == ^emoji_id)
        end
      end)

    case Ash.bulk_destroy(query, :destroy, %{},
           context: %{
             private: %{ash_discord?: true},
             shared: %{private: %{ash_discord?: true}}
           }
         ) do
      %Ash.BulkResult{status: :success} ->
        :ok

      result ->
        {:error, result}
    end
  end
end
