defmodule AshDiscord.Consumer.Payloads.PollVoteChangeEvent do
  @moduledoc """
  TypedStruct wrapper for Discord MESSAGE_POLL_VOTE_ADD/REMOVE event data.

  Wraps `Nostrum.Struct.Event.PollVoteChange.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.PollVoteChange struct"
  end
end
