defmodule AshDiscord.Consumer.Handler.Message.Poll.Vote do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec add(
          poll_vote_add :: Payloads.PollVoteChangeEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def add(poll_vote_add, _ws_state, context) do
    case context.resource do
      nil ->
        :ok

      _resource ->
        case Handler.invoke_configured_action(
               :MESSAGE_POLL_VOTE_ADD,
               %{
                 user_id: poll_vote_add.user_id,
                 message_id: poll_vote_add.message_id,
                 answer_id: poll_vote_add.answer_id
               },
               %{data: poll_vote_add},
               context
             ) do
          {:ok, _} ->
            :ok

          {:error, error} ->
            Logger.error(
              "Failed to save poll vote for user #{poll_vote_add.user_id} on message #{poll_vote_add.message_id}: #{inspect(error)}"
            )

            # Don't crash the consumer
            :ok
        end
    end
  end

  @spec remove(
          poll_vote_remove :: Payloads.PollVoteChangeEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def remove(poll_vote_remove, _ws_state, context) do
    case context.resource do
      nil ->
        :ok

      _resource ->
        case Handler.invoke_configured_action(
               :MESSAGE_POLL_VOTE_REMOVE,
               %{
                 user_id: poll_vote_remove.user_id,
                 message_id: poll_vote_remove.message_id,
                 answer_id: poll_vote_remove.answer_id
               },
               %{},
               context
             ) do
          {:ok, _} ->
            :ok

          {:error, error} ->
            Logger.error(
              "Failed to delete poll vote for user #{poll_vote_remove.user_id} on message #{poll_vote_remove.message_id}: #{inspect(error)}"
            )

            :ok
        end
    end
  end
end
