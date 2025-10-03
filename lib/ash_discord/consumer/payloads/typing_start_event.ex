defmodule AshDiscord.Consumer.Payloads.TypingStartEvent do
  @moduledoc """
  TypedStruct wrapper for Discord TYPING_START event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.TypingStart.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :channel_id, :integer,
      allow_nil?: false,
      description: "Channel in which the user started typing"

    field :guild_id, :integer,
      description: "ID of the guild where the user started typing (if applicable)"

    field :user_id, :integer, allow_nil?: false, description: "ID of the user who started typing"

    field :timestamp, :utc_datetime,
      allow_nil?: false,
      description: "Unix time (in seconds) of when the user started typing"

    field :member, AshDiscord.Consumer.Payloads.Member,
      description: "Member who started typing (if in a guild)"
  end

  @doc """
  Create a TypingStartEvent TypedStruct from a Nostrum TypingStart event struct.

  Accepts a `Nostrum.Struct.Event.TypingStart.t()` and creates an AshDiscord TypingStartEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.TypingStart{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
