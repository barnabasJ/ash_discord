defmodule AshDiscord.Consumer.Handler.Message.Reaction do
  require Logger
  require Ash.Query

  alias AshDiscord.Consumer.Payloads

  @spec add(
          consumer :: module(),
          reaction_add :: Payloads.MessageReactionAddEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def add(consumer, reaction_add, _ws_state, _context) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_message_reaction_resource(consumer) do
      {:ok, resource} ->
        resource
        |> Ash.Changeset.for_create(
          :from_discord,
          %{
            data: reaction_add
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
          reaction_remove :: Payloads.MessageReactionRemoveEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def remove(consumer, reaction_remove, _ws_state, _context) do
    Logger.info("AshDiscord: Message reaction removal requested")

    case AshDiscord.Consumer.Info.ash_discord_consumer_message_reaction_resource(consumer) do
      {:ok, resource} ->
        Logger.info("AshDiscord: Found message reaction resource: #{inspect(resource)}")

        # Find and destroy the reaction based on user_id, message_id, emoji_name, and emoji_id
        user_id = reaction_remove.user_id
        message_id = reaction_remove.message_id
        emoji_name = reaction_remove.emoji.name
        emoji_id = reaction_remove.emoji.id

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

  @spec remove_all(
          consumer :: module(),
          reaction_remove_all :: Payloads.MessageReactionRemoveAllEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def remove_all(consumer, reaction_remove_all, _ws_state, _context) do
    Logger.info("AshDiscord: Message reaction remove all requested")

    case AshDiscord.Consumer.Info.ash_discord_consumer_message_reaction_resource(consumer) do
      {:ok, resource} ->
        Logger.info("AshDiscord: Found message reaction resource: #{inspect(resource)}")

        # Get the message_id from the reaction_remove_all
        # Note: MessageReactionRemoveAll doesn't have emoji field, it removes ALL reactions
        message_id = reaction_remove_all.message_id
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

  @spec remove_emoji(
          consumer :: module(),
          reaction_remove_emoji :: Payloads.MessageReactionRemoveEmojiEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def remove_emoji(_consumer, _reaction_remove_emoji, _ws_state, _context) do
    :ok
  end
end
