defmodule AshDiscord.Consumer.Payloads.Sticker do
  @moduledoc """
  TypedStruct wrapper for Discord Sticker data.

  Wraps `Nostrum.Struct.Sticker.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Sticker struct"
  end
end
