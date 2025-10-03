defmodule AshDiscord.Consumer.Payloads.MessageReactionRemoveEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_REACTION_REMOVE event data.

  Wraps `Nostrum.Struct.Event.MessageReactionRemove.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.MessageReactionRemove struct"
  end
end
