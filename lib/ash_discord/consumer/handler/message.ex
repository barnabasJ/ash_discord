defmodule AshDiscord.Consumer.Handler.Message do
  require Logger
  require Ash.Query

  @spec create(
          consumer :: module(),
          message :: Nostrum.Struct.Message.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def create(consumer, message, _ws_state, _context) do
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
               discord_struct: message,
               channel_discord_id: message.channel_id,
               guild_discord_id: message.guild_id,
               discord_id: message.id
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
          consumer :: module(),
          message_data ::
            {old_message :: Nostrum.Struct.Message.t() | nil,
             updated_message :: Nostrum.Struct.Message.t()},
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def update(consumer, {_old_message, message}, _ws_state, _context) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(consumer) do
      {:ok, message_resource} ->
        # Update the existing message - provide channel and guild IDs from the message struct
        case message_resource
             |> Ash.Changeset.for_create(:from_discord, %{
               discord_struct: message,
               channel_discord_id: message.channel_id,
               guild_discord_id: message.guild_id,
               discord_id: message.id
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
          consumer :: module(),
          data :: Nostrum.Struct.Event.MessageDelete.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def delete(consumer, data, _ws_state, _context) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(consumer) do
      {:ok, message_resource} ->
        require Ash.Query

        # Delete the message by discord_id
        query =
          message_resource
          |> Ash.Query.filter(discord_id: data.id)

        case Ash.bulk_destroy(query, :destroy, %{},
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               }
             ) do
          %Ash.BulkResult{status: :success} ->
            :ok

          result ->
            Logger.error("Failed to delete message #{data.id}: #{inspect(result)}")
            :ok
        end

      :error ->
        # No message resource configured
        :ok
    end
  end

  @spec bulk(
          consumer :: module(),
          data :: Nostrum.Struct.Event.MessageDeleteBulk.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def bulk(consumer, data, _ws_state, _context) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(consumer) do
      {:ok, message_resource} ->
        # Handle empty IDs list gracefully
        if data.ids == [] do
          :ok
        else
          # Delete all messages by discord_id
          # We need to build a filter that checks if discord_id is in the list
          query =
            message_resource
            |> Ash.Query.filter(discord_id in ^data.ids)

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
          consumer :: module(),
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def ack(_consumer, _data, _ws_state, _context) do
    :ok
  end
end
