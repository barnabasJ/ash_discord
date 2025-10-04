defmodule AshDiscord.Consumer.Payloads.Member do
  @moduledoc """
  TypedStruct wrapper for Discord Guild Member data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Guild.Member.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :user_id, :integer, description: "The user ID (can be nil for partial Member objects)"
    field :nick, :string, description: "The nickname of the member"
    field :roles, {:array, :integer}, allow_nil?: false, description: "A list of role ids"
    field :joined_at, :integer, description: "Unix timestamp when the user joined the guild"
    field :deaf, :boolean, description: "Whether the user is deafened in voice channels"
    field :mute, :boolean, description: "Whether the user is muted in voice channels"

    field :communication_disabled_until, :utc_datetime,
      description: "When the user's timeout will expire (if they're timed out)"

    field :premium_since, :utc_datetime, description: "When the user started boosting the guild"
    field :avatar, :string, description: "The member's guild-specific avatar hash"

    field :pending, :boolean,
      description:
        "Whether the user has not yet passed the guild's Membership Screening requirements"

    field :flags, :integer, description: "Guild member flags"
  end

  @doc """
  Create a Member TypedStruct from a Nostrum Guild.Member struct.

  Accepts a `Nostrum.Struct.Guild.Member.t()` and creates an AshDiscord Member TypedStruct.
  If already a Payloads.Member struct, returns it as-is.
  """
  # TODO: This clause shouldn't be necessary - Ash's type system should handle this.
  # When we pass %Payloads.Member{} to Ash.Changeset.for_create(..., %{data: member}),
  # Ash calls cast_input/2 which calls .new() again. This should be a no-op for
  # already-typed data. Investigate if Ash.TypedStruct can handle this automatically.
  def new(%__MODULE__{} = member) do
    {:ok, member}
  end

  def new(%Nostrum.Struct.Guild.Member{} = nostrum_member) do
    super(Map.from_struct(nostrum_member))
  end
end
