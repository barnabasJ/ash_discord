defmodule AshDiscord.Consumer.Payloads.Channel do
  @moduledoc """
  TypedStruct wrapper for Discord Channel data.

  Wraps `Nostrum.Struct.Channel.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Channel struct"
  end
end
