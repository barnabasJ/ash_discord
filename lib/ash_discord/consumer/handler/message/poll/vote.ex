defmodule AshDiscord.Consumer.Handler.Message.Poll.Vote do
  require Logger
  require Ash.Query

  alias AshDiscord.Consumer.Payloads

  @spec add(
          poll_vote_add :: Payloads.PollVoteChangeEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def add(poll_vote_add, _ws_state, context) do
    consumer = context.consumer

    case AshDiscord.Consumer.Info.ash_discord_consumer_message_poll_vote_resource(consumer) do
      {:ok, resource} ->
        case resource
             |> Ash.Changeset.for_create(:from_discord, %{
               data: poll_vote_add
             })
             |> Ash.Changeset.set_context(%{
               private: %{ash_discord?: true},
               shared: %{private: %{ash_discord?: true}}
             })
             |> Ash.create() do
          {:ok, _poll_vote_record} ->
            :ok

          {:error, error} ->
            Logger.error(
              "Failed to save poll vote for user #{poll_vote_add.user_id} on message #{poll_vote_add.message_id}: #{inspect(error)}"
            )

            # Don't crash the consumer
            :ok
        end

      :error ->
        # No message poll vote resource configured
        :ok
    end
  end

  @spec remove(
          poll_vote_remove :: Payloads.PollVoteChangeEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def remove(poll_vote_remove, _ws_state, context) do
    consumer = context.consumer

    case AshDiscord.Consumer.Info.ash_discord_consumer_message_poll_vote_resource(consumer) do
      {:ok, resource} ->
        # Delete the poll vote by user_id, message_id, and answer_id
        query =
          resource
          |> Ash.Query.filter(user_id == ^poll_vote_remove.user_id)
          |> Ash.Query.filter(message_id == ^poll_vote_remove.message_id)
          |> Ash.Query.filter(answer_id == ^poll_vote_remove.answer_id)

        case Ash.bulk_destroy(query, :destroy, %{},
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               }
             ) do
          %Ash.BulkResult{status: :success} ->
            :ok

          result ->
            Logger.error(
              "Failed to delete poll vote for user #{poll_vote_remove.user_id} on message #{poll_vote_remove.message_id}: #{inspect(result)}"
            )

            :ok
        end

      :error ->
        # No message poll vote resource configured
        :ok
    end
  end
end
