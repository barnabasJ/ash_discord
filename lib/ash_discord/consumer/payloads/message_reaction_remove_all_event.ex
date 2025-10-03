defmodule AshDiscord.Consumer.Payloads.MessageReactionRemoveAllEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_REACTION_REMOVE_ALL event data.

  Wraps `Nostrum.Struct.Event.MessageReactionRemoveAll.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.MessageReactionRemoveAll struct"
  end
end
