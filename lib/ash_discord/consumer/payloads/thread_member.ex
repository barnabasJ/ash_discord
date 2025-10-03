defmodule AshDiscord.Consumer.Payloads.ThreadMember do
  @moduledoc """
  TypedStruct wrapper for Discord ThreadMember data.

  Wraps `Nostrum.Struct.ThreadMember.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.ThreadMember struct"
  end
end
