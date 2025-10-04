defmodule AshDiscord.Consumer.Handler.Message.Reaction do
  require Logger
  require Ash.Query

  @spec add(
          consumer :: module(),
          data :: Nostrum.Struct.Event.MessageReactionAdd.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def add(consumer, data, _ws_state, _context) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_message_reaction_resource(consumer) do
      {:ok, resource} ->
        resource
        |> Ash.Changeset.for_create(
          :from_discord,
          %{
            data: data
          },
          context: %{
            private: %{ash_discord?: true},
            shared: %{private: %{ash_discord?: true}}
          }
        )
        |> Ash.create()

      :error ->
        Logger.warning("No message reaction resource configured")
        {:error, "No message reaction resource configured"}
    end

    :ok
  end

  @spec remove(
          consumer :: module(),
          data :: Nostrum.Struct.Event.MessageReactionRemove.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def remove(consumer, %Nostrum.Struct.Event.MessageReactionRemove{} = data, _ws_state, _context) do
    Logger.info("AshDiscord: Message reaction removal requested")

    case AshDiscord.Consumer.Info.ash_discord_consumer_message_reaction_resource(consumer) do
      {:ok, resource} ->
        Logger.info("AshDiscord: Found message reaction resource: #{inspect(resource)}")

        # Find and destroy the reaction based on user_id, message_id, emoji_name, and emoji_id
        user_id = data.user_id
        message_id = data.message_id
        emoji_name = data.emoji.name
        emoji_id = data.emoji.id

        Logger.info(
          "AshDiscord: Looking for reaction with user_id=#{user_id}, message_id=#{message_id}, emoji_name=#{emoji_name}, emoji_id=#{inspect(emoji_id)}"
        )

        # Build filters one by one to avoid compilation issues
        query =
          resource
          |> Ash.Query.new()
          |> Ash.Query.filter(user_id: user_id)
          |> Ash.Query.filter(message_id: message_id)
          |> Ash.Query.filter(emoji_name: emoji_name)
          |> then(fn q ->
            if is_nil(emoji_id) do
              Ash.Query.filter(q, is_nil(emoji_id))
            else
              Ash.Query.filter(q, emoji_id: emoji_id)
            end
          end)
          |> Ash.Query.set_context(%{
            private: %{ash_discord?: true},
            shared: %{private: %{ash_discord?: true}}
          })

        case Ash.bulk_destroy(
               query,
               :destroy,
               %{},
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               }
             ) do
          %Ash.BulkResult{status: :success} ->
            Logger.info("AshDiscord: Successfully removed reaction")
            :ok

          %Ash.BulkResult{errors: errors} ->
            Logger.error("AshDiscord: Failed to remove reaction: #{inspect(errors)}")
            {:error, errors}
        end

      :error ->
        Logger.info("AshDiscord: No message reaction resource configured")
        :ok
    end
  end

  @spec all(
          consumer :: module(),
          data :: Nostrum.Struct.Event.MessageReactionRemoveAll.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def all(consumer, data, _ws_state, _context) do
    Logger.info("AshDiscord: Message reaction remove all requested")

    case AshDiscord.Consumer.Info.ash_discord_consumer_message_reaction_resource(consumer) do
      {:ok, resource} ->
        Logger.info("AshDiscord: Found message reaction resource: #{inspect(resource)}")

        # Get the message_id from the data
        # Note: MessageReactionRemoveAll doesn't have emoji field, it removes ALL reactions
        message_id = Map.get(data, :message_id)
        emoji_name = nil
        emoji_id = nil

        Logger.info(
          "AshDiscord: Removing all reactions for message_id=#{message_id}, emoji_name=#{emoji_name}, emoji_id=#{inspect(emoji_id)}"
        )

        # Build query - if emoji is present, remove only that emoji, otherwise remove all reactions
        query =
          if emoji_name || emoji_id do
            resource
            |> Ash.Query.new()
            |> Ash.Query.filter(message_id: message_id)
            |> Ash.Query.filter(emoji_name: emoji_name)
            |> then(fn q ->
              if is_nil(emoji_id) do
                Ash.Query.filter(q, is_nil(emoji_id))
              else
                Ash.Query.filter(q, emoji_id: emoji_id)
              end
            end)
            |> Ash.Query.set_context(%{
              private: %{ash_discord?: true},
              shared: %{private: %{ash_discord?: true}}
            })
          else
            resource
            |> Ash.Query.new()
            |> Ash.Query.filter(message_id: message_id)
            |> Ash.Query.set_context(%{
              private: %{ash_discord?: true},
              shared: %{private: %{ash_discord?: true}}
            })
          end

        case Ash.read(query) do
          {:ok, []} ->
            Logger.info("AshDiscord: No reactions found to remove")
            :ok

          {:ok, reactions} ->
            Logger.info("AshDiscord: Found #{length(reactions)} reactions to remove")

            results =
              Enum.map(reactions, fn reaction ->
                Ash.destroy(reaction,
                  action: :destroy,
                  context: %{
                    private: %{ash_discord?: true},
                    shared: %{private: %{ash_discord?: true}}
                  }
                )
              end)

            # Check if any destroy failed
            case Enum.find(results, fn
                   :ok -> false
                   {:error, _} -> true
                 end) do
              nil ->
                Logger.info("AshDiscord: Successfully removed all reactions")
                :ok

              {:error, error} ->
                Logger.error("AshDiscord: Failed to remove some reactions: #{inspect(error)}")
                {:error, error}
            end

          {:error, error} ->
            Logger.error("AshDiscord: Failed to query reactions: #{inspect(error)}")
            {:error, error}
        end

      :error ->
        Logger.info("AshDiscord: No message reaction resource configured")
        :ok
    end
  end

  @spec emoji(
          consumer :: module(),
          data :: Nostrum.Struct.Event.MessageReactionRemoveEmoji.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def emoji(_consumer, _data, _ws_state, _context) do
    :ok
  end
end
