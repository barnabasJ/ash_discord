defmodule AshDiscord.Consumer.Handler.Message do
  require Logger
  require Ash.Query

  alias AshDiscord.Consumer.Payloads

  @spec create(
          message :: Payloads.Message.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def create(message, _ws_state, context) do
    consumer = context.consumer

    with {:ok, message_resource} <-
           AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(consumer),
         {:ok, store_bot_messages} <-
           AshDiscord.Consumer.Info.ash_discord_consumer_store_bot_messages(consumer) do
      Logger.debug("Message resource found: #{inspect(message_resource)}")

      # Skip bot messages if store_bot_messages is false
      if message.author.bot && !store_bot_messages do
        :ok
      else
        case message_resource
             |> Ash.Changeset.for_create(:from_discord, %{
               data: message
             })
             |> Ash.Changeset.set_context(%{
               private: %{ash_discord?: true},
               shared: %{private: %{ash_discord?: true}}
             })
             |> Ash.create() do
          {:ok, _message_record} ->
            :ok

          {:error, error} ->
            Logger.error("Failed to save message #{message.id}: #{inspect(error)}")
            # Don't crash the consumer
            :ok
        end
      end
    else
      :error ->
        # No message resource configured
        :ok
    end
  end

  @spec update(
          message_update :: Payloads.MessageUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def update(%Payloads.MessageUpdate{updated_message: message}, _ws_state, context) do
    consumer = context.consumer

    case AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(consumer) do
      {:ok, message_resource} ->
        # Update the existing message - provide channel and guild IDs from the message struct
        case message_resource
             |> Ash.Changeset.for_create(:from_discord, %{
               data: message
             })
             |> Ash.Changeset.set_context(%{
               private: %{ash_discord?: true},
               shared: %{private: %{ash_discord?: true}}
             })
             |> Ash.create() do
          {:ok, _message_record} ->
            :ok

          {:error, error} ->
            Logger.error("Failed to update message #{message.id}: #{inspect(error)}")
            # Don't crash the consumer
            :ok
        end

      :error ->
        # No message resource configured
        :ok
    end
  end

  @spec delete(
          message_delete :: Payloads.MessageDeleteEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def delete(message_delete, _ws_state, context) do
    consumer = context.consumer

    case AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(consumer) do
      {:ok, message_resource} ->
        require Ash.Query

        # Delete the message by discord_id
        query =
          message_resource
          |> Ash.Query.filter(discord_id: message_delete.id)

        case Ash.bulk_destroy(query, :destroy, %{},
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               }
             ) do
          %Ash.BulkResult{status: :success} ->
            :ok

          result ->
            Logger.error("Failed to delete message #{message_delete.id}: #{inspect(result)}")
            :ok
        end

      :error ->
        # No message resource configured
        :ok
    end
  end

  @spec delete_bulk(
          message_delete_bulk :: Payloads.MessageDeleteBulkEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def delete_bulk(message_delete_bulk, _ws_state, context) do
    consumer = context.consumer

    case AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(consumer) do
      {:ok, message_resource} ->
        # Handle empty IDs list gracefully
        if message_delete_bulk.ids == [] do
          :ok
        else
          # Delete all messages by discord_id
          # We need to build a filter that checks if discord_id is in the list
          query =
            message_resource
            |> Ash.Query.filter(discord_id in ^message_delete_bulk.ids)

          case Ash.bulk_destroy(query, :destroy, %{},
                 context: %{
                   private: %{ash_discord?: true},
                   shared: %{private: %{ash_discord?: true}}
                 }
               ) do
            %Ash.BulkResult{status: :success} ->
              :ok

            result ->
              Logger.error("Failed to bulk delete messages: #{inspect(result)}")
              :ok
          end
        end

      :error ->
        # No message resource configured
        :ok
    end
  end

  @spec ack(
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def ack(_data, _ws_state, _context) do
    :ok
  end
end
