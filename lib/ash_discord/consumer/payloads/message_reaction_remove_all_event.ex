defmodule AshDiscord.Consumer.Payloads.MessageReactionRemoveAllEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_REACTION_REMOVE_ALL event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.MessageReactionRemoveAll.t()`.

  ## References
  - [Discord API - Message Reaction Remove All Event](https://discord.com/developers/docs/topics/gateway-events#message-reaction-remove-all)
  - [Nostrum - Event.MessageReactionRemoveAll](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.MessageReactionRemoveAll.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :channel_id, :integer,
      allow_nil?: false,
      description: "ID of the channel in which the message resides"

    field :message_id, :integer,
      allow_nil?: false,
      description: "ID of the message from which all reactions were removed"

    field :guild_id, :integer, description: "Guild ID (if in a guild)"
  end

  @doc """
  Create a MessageReactionRemoveAllEvent TypedStruct from a Nostrum MessageReactionRemoveAll event struct.

  Accepts a `Nostrum.Struct.Event.MessageReactionRemoveAll.t()` and creates an AshDiscord MessageReactionRemoveAllEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.MessageReactionRemoveAll{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    super(attrs)
  end
end
