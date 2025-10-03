defmodule AshDiscord.Consumer.Payloads.ThreadListSyncEvent do
  @moduledoc """
  TypedStruct wrapper for Discord THREAD_LIST_SYNC event data.

  Wraps `Nostrum.Struct.Event.ThreadListSync.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.ThreadListSync struct"
  end
end
