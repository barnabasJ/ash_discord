defmodule AshDiscord.Consumer.Payloads.PollVoteChangeEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_POLL_VOTE_ADD/REMOVE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.PollVoteChange.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :user_id, :integer, allow_nil?: false, description: "ID of the user who voted"

    field :channel_id, :integer,
      allow_nil?: false,
      description: "ID of the channel containing the poll"

    field :message_id, :integer,
      allow_nil?: false,
      description: "ID of the message containing the poll"

    field :guild_id, :integer, allow_nil?: false, description: "ID of the guild"

    field :answer_id, :integer,
      allow_nil?: false,
      description: "ID of the answer that was voted for"

    field :type, :atom, allow_nil?: false, description: "Type of vote change (:add or :remove)"
  end

  @doc """
  Create a PollVoteChangeEvent TypedStruct from a Nostrum PollVoteChange event struct.

  Accepts a `Nostrum.Struct.Event.PollVoteChange.t()` and creates an AshDiscord PollVoteChangeEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.PollVoteChange{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
