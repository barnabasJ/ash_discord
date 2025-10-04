defmodule AshDiscord.Consumer.Payloads.ThreadListSyncEvent do
  @moduledoc """
  TypedStruct wrapper for Discord THREAD_LIST_SYNC event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.ThreadListSync.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer, allow_nil?: false, description: "The id of the guild"

    field :channel_ids, {:array, :integer},
      description: "Parent channel IDs whose threads are being synced"

    field :threads, {:array, :map},
      allow_nil?: false,
      description: "All active threads in the given channels"

    field :members, {:array, AshDiscord.Consumer.Payloads.ThreadMember},
      allow_nil?: false,
      description: "All thread member objects for the current user for threads in this event"
  end

  @doc """
  Create a ThreadListSyncEvent TypedStruct from a Nostrum ThreadListSync event struct.

  Accepts a `Nostrum.Struct.Event.ThreadListSync.t()` and creates an AshDiscord ThreadListSyncEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.ThreadListSync{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
