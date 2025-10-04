defmodule AshDiscord.Consumer.Payloads.Invite do
  @moduledoc """
  TypedStruct wrapper for Discord Invite data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Invite.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :code, :string, allow_nil?: false, description: "Invite code"
    field :guild, :map, description: "Partial guild object"
    field :guild_id, :integer, description: "Guild ID (from events)"
    field :channel, :map, description: "Partial channel object"
    field :channel_id, :integer, description: "Channel ID (from events)"
    field :inviter, :map, description: "User who created the invite"
    field :target_user, :map, description: "Target user for this invite"
    field :target_type, :integer, description: "Type of target for this invite"
    field :target_user_type, :integer, description: "Deprecated target user type"

    field :approximate_presence_count, :integer,
      description: "Approximate count of online members"

    field :approximate_member_count, :integer, description: "Approximate count of total members"
    field :uses, :integer, description: "Number of times this invite has been used"
    field :max_uses, :integer, description: "Maximum number of times this invite can be used"
    field :max_age, :integer, description: "Duration (in seconds) after which the invite expires"
    field :temporary, :boolean, description: "Whether this invite grants temporary membership"
    field :created_at, :string, description: "When this invite was created"
    field :expires_at, :string, description: "When this invite expires"
    field :stage_instance, :map, description: "Stage instance data if any"

    field :guild_scheduled_event, :map, description: "Guild scheduled event data if any"
  end

  @doc """
  Create an Invite TypedStruct from a Nostrum Invite struct.

  Accepts a `Nostrum.Struct.Invite.t()` and creates an AshDiscord Invite TypedStruct.
  Also handles being passed an Invite payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = invite_payload) do
    {:ok, invite_payload}
  end

  def new(%Nostrum.Struct.Invite{} = nostrum_invite) do
    super(Map.from_struct(nostrum_invite))
  end
end
