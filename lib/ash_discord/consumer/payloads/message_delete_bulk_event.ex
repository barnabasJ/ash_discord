defmodule AshDiscord.Consumer.Payloads.MessageDeleteBulkEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_DELETE_BULK event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.MessageDeleteBulk.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :deleted_messages, {:array, AshDiscord.Consumer.Payloads.Message},
      allow_nil?: false,
      description: "The cached deleted messages"

    field :channel_id, :integer,
      allow_nil?: false,
      description: "Channel id of the deleted messages"

    field :guild_id, :integer, description: "Guild id of the deleted messages (if in a guild)"

    field :ids, {:array, :integer},
      allow_nil?: false,
      description: "Ids of the deleted messages"
  end

  @doc """
  Create a MessageDeleteBulkEvent TypedStruct from a Nostrum MessageDeleteBulk event struct.

  Accepts a `Nostrum.Struct.Event.MessageDeleteBulk.t()` and creates an AshDiscord MessageDeleteBulkEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.MessageDeleteBulk{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
