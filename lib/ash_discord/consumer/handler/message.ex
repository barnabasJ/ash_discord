defmodule AshDiscord.Consumer.Handler.Message do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec create(
          message :: Payloads.Message.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(message, _ws_state, context) do
    consumer = context.consumer

    {:ok, store_bot_messages} =
      AshDiscord.Consumer.Info.ash_discord_consumer_store_bot_messages(consumer)

    Logger.debug("Message resource found: #{inspect(context.resource)}")

    # Skip bot messages if store_bot_messages is false
    if message.author.bot && !store_bot_messages do
      :ok
    else
      case Handler.invoke_configured_action(
             :MESSAGE_CREATE,
             %{discord_id: message.id},
             %{data: message},
             context
           ) do
        {:ok, _} ->
          :ok

        {:error, error} ->
          Logger.error("Failed to save message #{message.id}: #{inspect(error)}")
          # Don't crash the consumer
          :ok
      end
    end
  end

  @spec update(
          message_update :: Payloads.MessageUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.MessageUpdate{updated_message: message}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :MESSAGE_UPDATE,
           %{discord_id: message.id},
           %{data: message},
           context
         ) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.error("Failed to update message #{message.id}: #{inspect(error)}")
        # Don't crash the consumer
        :ok
    end
  end

  @spec delete(
          message_delete :: Payloads.MessageDeleteEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(message_delete, _ws_state, context) do
    case Handler.invoke_configured_action(
           :MESSAGE_DELETE,
           %{discord_id: message_delete.id},
           %{},
           context
         ) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.error("Failed to delete message #{message_delete.id}: #{inspect(error)}")
        :ok
    end
  end

  @spec delete_bulk(
          message_delete_bulk :: Payloads.MessageDeleteBulkEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete_bulk(message_delete_bulk, _ws_state, context) do
    # Handle empty IDs list gracefully
    if message_delete_bulk.ids == [] do
      :ok
    else
      case Handler.invoke_configured_action(
             :MESSAGE_DELETE_BULK,
             %{"discord_id" => %{"in" => message_delete_bulk.ids}},
             %{},
             context
           ) do
        {:ok, _} ->
          :ok

        {:error, error} ->
          Logger.error("Failed to bulk delete messages: #{inspect(error)}")
          :ok
      end
    end
  end

  @spec ack(
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def ack(data, _ws_state, context) do
    case Handler.invoke_configured_action(
           :MESSAGE_ACK,
           %{},
           %{data: data},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
