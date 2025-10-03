defmodule AshDiscord.Consumer.Payloads.User do
  @moduledoc """
  TypedStruct wrapper for Discord User data.

  Wraps `Nostrum.Struct.User.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.User struct"
  end
end
