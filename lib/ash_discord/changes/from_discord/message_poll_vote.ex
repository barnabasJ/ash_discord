defmodule AshDiscord.Changes.FromDiscord.MessagePollVote do
  @moduledoc """
  Transforms Discord MessagePollVote data into Ash resource attributes.

  This change handles creating/updating MessagePollVote resources from Discord data.
  Poll votes are tracked per user, message, and answer combination.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.PollVoteChangeEvent.t()` with poll vote event data
  - `:identity` - Map with `%{user_discord_id: integer, message_discord_id: integer, answer_id: integer}` for identification

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.PollVoteChangeEvent
        argument :identity, :map

        change AshDiscord.Changes.FromDiscord.MessagePollVote
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        nil ->
          # No data provided, use identity to construct minimal data
          identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)

          case validate_identity(identity) do
            {:ok, validated_identity} ->
              transform_poll_vote(changeset, validated_identity)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.PollVoteChangeEvent{} = poll_vote_data ->
          # Data provided directly, use it
          transform_poll_vote(changeset, poll_vote_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.PollVoteChangeEvent{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp validate_identity(
         %{
           user_discord_id: user_discord_id,
           message_discord_id: message_discord_id,
           answer_id: answer_id
         } = identity
       )
       when not is_nil(user_discord_id) and not is_nil(message_discord_id) and
              not is_nil(answer_id) do
    {:ok, identity}
  end

  defp validate_identity(_) do
    {:error,
     "MessagePollVote requires identity with user_discord_id, message_discord_id, and answer_id"}
  end

  defp transform_poll_vote(changeset, poll_vote_data) do
    changeset
    |> maybe_set_attribute(
      :user_discord_id,
      Map.get(poll_vote_data, :user_discord_id) || Map.get(poll_vote_data, :user_id)
    )
    |> maybe_set_attribute(
      :message_discord_id,
      Map.get(poll_vote_data, :message_discord_id) || Map.get(poll_vote_data, :message_id)
    )
    |> maybe_set_attribute(
      :channel_discord_id,
      Map.get(poll_vote_data, :channel_discord_id) || Map.get(poll_vote_data, :channel_id)
    )
    |> maybe_set_attribute(
      :guild_discord_id,
      Map.get(poll_vote_data, :guild_discord_id) || Map.get(poll_vote_data, :guild_id)
    )
    |> maybe_set_attribute(:answer_id, Map.get(poll_vote_data, :answer_id))
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
