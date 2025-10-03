defmodule AshDiscord.Consumer.Payloads.InviteCreateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord INVITE_CREATE event data.

  Wraps `Nostrum.Struct.Event.InviteCreate.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.InviteCreate struct"
  end
end
