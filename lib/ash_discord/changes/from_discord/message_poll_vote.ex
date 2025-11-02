defmodule AshDiscord.Changes.FromDiscord.MessagePollVote do
  @moduledoc """
  Transforms Discord MessagePollVote data into Ash resource attributes.

  This change handles creating/updating MessagePollVote resources from Discord event data.
  Poll votes are tracked per user, message, and answer combination.

  Poll votes are event-only data and cannot be fetched from Discord API, so only
  the `:data` argument is supported.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.PollVoteChangeEvent.t()` with poll vote event data

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.PollVoteChangeEvent, allow_nil?: false

        change AshDiscord.Changes.FromDiscord.MessagePollVote
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        %Payloads.PollVoteChangeEvent{} = poll_vote_data ->
          transform_poll_vote(changeset, poll_vote_data)

        nil ->
          Ash.Changeset.add_error(
            changeset,
            "MessagePollVote requires data argument - poll votes are event-only and not fetchable from API"
          )

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.PollVoteChangeEvent{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_poll_vote(changeset, poll_vote_data) do
    changeset
    |> maybe_set_attribute(:user_discord_id, poll_vote_data.user_id)
    |> maybe_set_attribute(:message_discord_id, poll_vote_data.message_id)
    |> maybe_set_attribute(:channel_discord_id, poll_vote_data.channel_id)
    |> maybe_set_attribute(:guild_discord_id, poll_vote_data.guild_id)
    |> maybe_set_attribute(:answer_id, poll_vote_data.answer_id)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    resource = changeset.resource

    if Ash.Resource.Info.attribute(resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end
end
