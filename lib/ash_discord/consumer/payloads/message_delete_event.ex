defmodule AshDiscord.Consumer.Payloads.MessageDeleteEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_DELETE event data.

  Wraps `Nostrum.Struct.Event.MessageDelete.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.MessageDelete struct"
  end
end
