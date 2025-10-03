defmodule AshDiscord.Consumer.Payloads.MessageReactionAddEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_REACTION_ADD event data.

  Wraps `Nostrum.Struct.Event.MessageReactionAdd.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.MessageReactionAdd struct"
  end
end
