defmodule AshDiscord.Consumer.Payloads.MessageReactionAddEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_REACTION_ADD event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.MessageReactionAdd.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :user_id, :integer,
      allow_nil?: false,
      description: "ID of the user who added the reaction"

    field :channel_id, :integer,
      allow_nil?: false,
      description: "Channel in which the reaction was added"

    field :message_id, :integer,
      allow_nil?: false,
      description: "Message to which the reaction was added"

    field :guild_id, :integer, description: "Guild ID (if in a guild)"

    field :member, AshDiscord.Consumer.Payloads.Member,
      description: "Member who added the reaction (if in a guild)"

    field :emoji, :map, allow_nil?: false, description: "Emoji used to react"
  end

  @doc """
  Create a MessageReactionAddEvent TypedStruct from a Nostrum MessageReactionAdd event struct.

  Accepts a `Nostrum.Struct.Event.MessageReactionAdd.t()` and creates an AshDiscord MessageReactionAddEvent TypedStruct.
  If already a MessageReactionAddEvent struct, returns it as-is.
  """
  # TODO: This clause shouldn't be necessary - Ash's type system should handle this.
  # When we pass %MessageReactionAddEvent{} to Ash.Changeset.for_create(..., %{data: event}),
  # Ash calls cast_input/2 which calls .new() again. This should be a no-op for
  # already-typed data. Investigate if Ash.TypedStruct can handle this automatically.
  def new(%__MODULE__{} = event) do
    {:ok, event}
  end

  def new(%Nostrum.Struct.Event.MessageReactionAdd{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
