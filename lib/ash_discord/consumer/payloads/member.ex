defmodule AshDiscord.Consumer.Payloads.Member do
  @moduledoc """
  TypedStruct wrapper for Discord Guild Member data.

  Wraps `Nostrum.Struct.Guild.Member.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Guild.Member struct"
  end
end
