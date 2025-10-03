defmodule AshDiscord.Consumer.Payloads.TypingStartEvent do
  @moduledoc """
  TypedStruct wrapper for Discord TYPING_START event data.

  Wraps `Nostrum.Struct.Event.TypingStart.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.TypingStart struct"
  end
end
