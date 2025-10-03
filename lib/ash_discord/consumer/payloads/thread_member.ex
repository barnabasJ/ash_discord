defmodule AshDiscord.Consumer.Payloads.ThreadMember do
  @moduledoc """
  TypedStruct wrapper for Discord ThreadMember data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.ThreadMember.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer, description: "The id of the thread (omitted within GUILD_CREATE events)"

    field :user_id, :integer,
      description: "The id of the user (omitted within GUILD_CREATE events)"

    field :join_timestamp, :utc_datetime,
      allow_nil?: false,
      description: "The timestamp of when the user last joined the thread"

    field :flags, :integer, allow_nil?: false, description: "User thread settings flags"
    field :guild_id, :integer, description: "ID of the guild containing the thread"
  end

  @doc """
  Create a ThreadMember TypedStruct from a Nostrum ThreadMember struct.

  Accepts a `Nostrum.Struct.ThreadMember.t()` and creates an AshDiscord ThreadMember TypedStruct.
  """
  def new(%Nostrum.Struct.ThreadMember{} = nostrum_thread_member) do
    super(Map.from_struct(nostrum_thread_member))
  end
end
