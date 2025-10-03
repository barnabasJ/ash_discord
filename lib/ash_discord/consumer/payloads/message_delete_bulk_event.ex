defmodule AshDiscord.Consumer.Payloads.MessageDeleteBulkEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_DELETE_BULK event data.

  Wraps `Nostrum.Struct.Event.MessageDeleteBulk.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.MessageDeleteBulk struct"
  end
end
