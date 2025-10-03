defmodule AshDiscord.Consumer.Payloads.InviteCreateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord INVITE_CREATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.InviteCreate.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :channel_id, :integer,
      allow_nil?: false,
      description: "Channel ID of the channel this invite is for"

    field :code, :string, allow_nil?: false, description: "Unique invite code"

    field :created_at, :string,
      allow_nil?: false,
      description: "Time at which the invite was created"

    field :guild_id, :integer, description: "Guild ID of the invite"

    field :inviter, AshDiscord.Consumer.Payloads.User, description: "User that created the invite"

    field :max_age, :integer,
      allow_nil?: false,
      description: "How long the invite is valid for (in seconds)"

    field :max_uses, :integer,
      allow_nil?: false,
      description: "Maximum number of times the invite can be used"

    field :target_user, AshDiscord.Consumer.Payloads.User,
      description: "Target user for this invite"

    field :target_user_type, :integer, description: "Type of target user for this invite"

    field :temporary, :boolean,
      allow_nil?: false,
      description: "Whether this invite grants temporary membership"

    field :uses, :integer,
      allow_nil?: false,
      description: "How many times the invite has been used"
  end

  @doc """
  Create an InviteCreateEvent TypedStruct from a Nostrum InviteCreate event struct.

  Accepts a `Nostrum.Struct.Event.InviteCreate.t()` and creates an AshDiscord InviteCreateEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.InviteCreate{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
