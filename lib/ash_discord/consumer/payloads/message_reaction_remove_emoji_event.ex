defmodule AshDiscord.Consumer.Payloads.MessageReactionRemoveEmojiEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_REACTION_REMOVE_EMOJI event data.

  Wraps `Nostrum.Struct.Event.MessageReactionRemoveEmoji.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.MessageReactionRemoveEmoji struct"
  end
end
