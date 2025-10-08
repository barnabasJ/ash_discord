defmodule AshDiscord.Consumer.Payloads.ThreadMember do
  @moduledoc """
  TypedStruct wrapper for Discord ThreadMember data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.ThreadMember.t()`.

  ## References
  - [Discord API - Thread Member](https://discord.com/developers/docs/resources/channel#thread-member-object)
  - [Nostrum - ThreadMember](https://hexdocs.pm/nostrum/Nostrum.Struct.ThreadMember.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer,
      allow_nil?: true,
      description: "The id of the thread (omitted within GUILD_CREATE events)"

    field :user_id, :integer,
      allow_nil?: true,
      description: "The id of the user (omitted within GUILD_CREATE events)"

    field :join_timestamp, :utc_datetime,
      allow_nil?: false,
      description: "The timestamp of when the user last joined the thread"

    field :flags, :integer, allow_nil?: false, description: "User thread settings flags"

    field :guild_id, :integer,
      allow_nil?: true,
      description: "ID of the guild containing the thread (Nostrum extension)"
  end

  @doc """
  Create a ThreadMember TypedStruct from a Nostrum ThreadMember struct.

  Accepts a `Nostrum.Struct.ThreadMember.t()` and creates an AshDiscord ThreadMember TypedStruct.
  Also handles being passed a ThreadMember payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = thread_member_payload) do
    {:ok, thread_member_payload}
  end

  def new(%Nostrum.Struct.ThreadMember{} = nostrum_thread_member) do
    super(Map.from_struct(nostrum_thread_member))
  end
end
