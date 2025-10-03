defmodule AshDiscord.Consumer.Payloads.ReadyEvent do
  @moduledoc """
  TypedStruct wrapper for Discord READY event data.

  Wraps `Nostrum.Struct.Event.Ready.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.Ready struct"
  end
end
