defmodule AshDiscord.Consumer.Payloads.Emoji do
  @moduledoc """
  TypedStruct wrapper for Discord Emoji data.

  Wraps `Nostrum.Struct.Emoji.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Emoji struct"
  end
end
