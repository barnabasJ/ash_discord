defmodule AshDiscord.Consumer.Handler.Channel do
  require Logger
  require Ash.Query

  alias AshDiscord.Consumer.Payloads

  @spec create(
          channel :: Payloads.Channel.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(channel, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: channel})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _channel_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec update(
          channel_update :: Payloads.ChannelUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.ChannelUpdate{new_channel: channel}, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: channel})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _channel_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec delete(
          channel :: Payloads.Channel.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(channel, _ws_state, context) do
    query =
      context.resource
      |> Ash.Query.filter(discord_id == ^channel.id)

    case Ash.bulk_destroy(query, :destroy, %{},
           context: %{
             private: %{ash_discord?: true},
             shared: %{private: %{ash_discord?: true}}
           }
         ) do
      %Ash.BulkResult{status: :success} ->
        :ok

      result ->
        {:error, result}
    end
  end
end
