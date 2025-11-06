defmodule AshDiscord.Consumer.Payloads.MessageReactionRemoveEmojiEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_REACTION_REMOVE_EMOJI event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.MessageReactionRemoveEmoji.t()`.

  ## References
  - [Discord API - Message Reaction Remove Emoji Event](https://discord.com/developers/docs/topics/gateway-events#message-reaction-remove-emoji)
  - [Nostrum - Event.MessageReactionRemoveEmoji](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.MessageReactionRemoveEmoji.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :channel_id, :integer,
      allow_nil?: false,
      description: "Channel in which the message resides"

    field :guild_id, :integer, description: "Guild on which the message resides (if applicable)"
    field :message_id, :integer, allow_nil?: false, description: "ID of the message"
    field :emoji, :map, allow_nil?: false, description: "Emoji that was removed"
  end

  @doc """
  Create a MessageReactionRemoveEmojiEvent TypedStruct from a Nostrum MessageReactionRemoveEmoji event struct.

  Accepts a `Nostrum.Struct.Event.MessageReactionRemoveEmoji.t()` and creates an AshDiscord MessageReactionRemoveEmojiEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.MessageReactionRemoveEmoji{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    super(attrs)
  end
end
