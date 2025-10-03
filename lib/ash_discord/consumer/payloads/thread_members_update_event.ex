defmodule AshDiscord.Consumer.Payloads.ThreadMembersUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord THREAD_MEMBERS_UPDATE event data.

  Wraps `Nostrum.Struct.Event.ThreadMembersUpdate.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.ThreadMembersUpdate struct"
  end
end
