defmodule AshDiscord.Consumer.Payloads.MessageDeleteEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_DELETE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.MessageDelete.t()`.

  ## References
  - [Discord API - Message Delete Event](https://discord.com/developers/docs/topics/gateway-events#message-delete)
  - [Nostrum - Event.MessageDelete](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.MessageDelete.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "Id of the deleted message"

    field :channel_id, :integer,
      allow_nil?: false,
      description: "Channel id of the deleted message"

    field :guild_id, :integer, description: "Guild id of the deleted message (if in a guild)"

    field :deleted_message, AshDiscord.Consumer.Payloads.Message,
      description: "The cached deleted message (if available)"
  end

  @doc """
  Create a MessageDeleteEvent TypedStruct from a Nostrum MessageDelete event struct.

  Accepts a `Nostrum.Struct.Event.MessageDelete.t()` and creates an AshDiscord MessageDeleteEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.MessageDelete{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    super(attrs)
  end
end
