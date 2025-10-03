defmodule AshDiscord.Consumer.Payloads.InviteDeleteEvent do
  @moduledoc """
  TypedStruct wrapper for Discord INVITE_DELETE event data.

  Wraps `Nostrum.Struct.Event.InviteDelete.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.InviteDelete struct"
  end
end
