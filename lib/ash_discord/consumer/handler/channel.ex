defmodule AshDiscord.Consumer.Handler.Channel do
  require Logger
  require Ash.Query

  @spec create(
          consumer :: module(),
          channel :: Nostrum.Struct.Channel.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def create(consumer, channel, _ws_state, _context) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_channel_resource(consumer) do
      {:ok, resource} ->
        resource
        |> Ash.Changeset.for_create(
          :from_discord,
          %{
            discord_id: channel.id,
            discord_struct: channel
          },
          context: %{
            private: %{ash_discord?: true},
            shared: %{private: %{ash_discord?: true}}
          }
        )
        |> Ash.create()

      :error ->
        Logger.warning("No channel resource configured")
        {:error, "No channel resource configured"}
    end

    :ok
  end

  @spec update(
          consumer :: module(),
          {old_channel :: Nostrum.Struct.Channel.t() | nil,
           new_channel :: Nostrum.Struct.Channel.t()},
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def update(consumer, {_old_channel, channel}, _ws_state, _context) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_channel_resource(consumer) do
      {:ok, resource} ->
        resource
        |> Ash.Changeset.for_create(
          :from_discord,
          %{
            discord_id: channel.id,
            discord_struct: channel
          },
          context: %{
            private: %{ash_discord?: true},
            shared: %{private: %{ash_discord?: true}}
          }
        )
        |> Ash.create()

      :error ->
        Logger.warning("No channel resource configured")
        {:error, "No channel resource configured"}
    end

    :ok
  end

  @spec delete(
          consumer :: module(),
          channel :: Nostrum.Struct.Channel.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def delete(consumer, channel, _ws_state, _context) do
    Logger.debug("AshDiscord: handle_channel_delete called with channel: #{inspect(channel)}")

    case AshDiscord.Consumer.Info.ash_discord_consumer_channel_resource(consumer) do
      {:ok, resource} ->
        Logger.info("AshDiscord: Channel resource found: #{inspect(resource)}")

        channel_discord_id = channel.id
        Logger.info("AshDiscord: Deleting channel #{channel_discord_id}")

        case resource
             |> Ash.Query.for_read(:read)
             |> Ash.Query.filter(discord_id: channel_discord_id)
             |> Ash.Query.set_context(%{
               private: %{ash_discord?: true},
               shared: %{private: %{ash_discord?: true}}
             })
             |> Ash.read() do
          {:ok, [channel_record]} ->
            Logger.info("AshDiscord: Found channel to delete: #{inspect(channel_record)}")

            case channel_record |> Ash.destroy(actor: %{role: :bot}) do
              :ok ->
                Logger.info("AshDiscord: Channel #{channel_discord_id} deleted successfully")
                :ok

              {:error, error} ->
                Logger.error(
                  "AshDiscord: Failed to delete channel #{channel_discord_id}: #{inspect(error)}"
                )

                :ok
            end

          {:ok, []} ->
            Logger.info("AshDiscord: Channel #{channel_discord_id} not found, nothing to delete")

            :ok

          {:error, error} ->
            Logger.error(
              "AshDiscord: Failed to query for channel #{channel_discord_id}: #{inspect(error)}"
            )

            :ok
        end

      :error ->
        Logger.debug("AshDiscord: No channel resource configured, skipping channel deletion")

        :ok
    end
  end
end
