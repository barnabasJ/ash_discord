defmodule AshDiscord.Consumer.Payloads.ThreadMembersUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord THREAD_MEMBERS_UPDATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.ThreadMembersUpdate.t()`.

  ## References
  - [Discord API - Thread Members Update Event](https://discord.com/developers/docs/topics/gateway-events#thread-members-update)
  - [Nostrum - Event.ThreadMembersUpdate](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.ThreadMembersUpdate.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, allow_nil?: false, description: "ID of the thread"
    field :guild_id, :integer, allow_nil?: false, description: "ID of the guild"

    field :member_count, :integer,
      allow_nil?: false,
      description: "Approximate number of members in the thread"

    field :added_members, {:array, AshDiscord.Consumer.Payloads.ThreadMember},
      description: "Users who were added to the thread"

    field :removed_member_ids, {:array, :integer},
      description: "IDs of users who were removed from the thread"
  end

  @doc """
  Create a ThreadMembersUpdateEvent TypedStruct from a Nostrum ThreadMembersUpdate event struct.

  Accepts a `Nostrum.Struct.Event.ThreadMembersUpdate.t()` and creates an AshDiscord ThreadMembersUpdateEvent TypedStruct.
  Also handles being passed a ThreadMembersUpdateEvent payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = event_payload) do
    {:ok, event_payload}
  end

  def new(%Nostrum.Struct.Event.ThreadMembersUpdate{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    super(attrs)
  end
end
