defmodule AshDiscord.Consumer.Payloads.MessageReactionRemoveEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_REACTION_REMOVE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.MessageReactionRemove.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :user_id, :integer, allow_nil?: false, description: "Author of the reaction"

    field :channel_id, :integer,
      allow_nil?: false,
      description: "ID of the channel in which the reaction was created"

    field :message_id, :integer,
      allow_nil?: false,
      description: "ID of the message to which the reaction was attached"

    field :guild_id, :integer, description: "Guild ID (if in a guild)"
    field :emoji, :map, allow_nil?: false, description: "Emoji used to react"
  end

  @doc """
  Create a MessageReactionRemoveEvent TypedStruct from a Nostrum MessageReactionRemove event struct.

  Accepts a `Nostrum.Struct.Event.MessageReactionRemove.t()` and creates an AshDiscord MessageReactionRemoveEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.MessageReactionRemove{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
