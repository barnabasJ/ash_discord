defmodule AshDiscord.Consumer.Payloads.Role do
  @moduledoc """
  TypedStruct wrapper for Discord Role data.

  Wraps `Nostrum.Struct.Guild.Role.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Guild.Role struct"
  end
end
