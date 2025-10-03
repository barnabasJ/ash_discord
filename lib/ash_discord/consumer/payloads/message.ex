defmodule AshDiscord.Consumer.Payloads.Message do
  @moduledoc """
  TypedStruct wrapper for Discord Message data.

  Wraps `Nostrum.Struct.Message.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Message struct"
  end
end
