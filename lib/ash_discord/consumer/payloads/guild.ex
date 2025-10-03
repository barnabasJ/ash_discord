defmodule AshDiscord.Consumer.Payloads.Guild do
  @moduledoc """
  TypedStruct wrapper for Discord Guild data.

  Wraps `Nostrum.Struct.Guild.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Guild struct"
  end
end
