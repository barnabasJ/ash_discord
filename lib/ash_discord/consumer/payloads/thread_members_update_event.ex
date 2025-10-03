defmodule AshDiscord.Consumer.Payloads.ThreadMembersUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord THREAD_MEMBERS_UPDATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.ThreadMembersUpdate.t()`.
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
  """
  def new(%Nostrum.Struct.Event.ThreadMembersUpdate{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
