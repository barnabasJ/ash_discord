defmodule AshDiscord.Consumer.Handler.Channel do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec create(
          channel :: Payloads.Channel.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(channel, _ws_state, context) do
    case Handler.invoke_configured_action(
           :CHANNEL_CREATE,
           %{discord_id: channel.id},
           %{identity: channel.id, data: channel},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec update(
          channel_update :: Payloads.ChannelUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.ChannelUpdate{new_channel: channel}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :CHANNEL_UPDATE,
           %{discord_id: channel.id},
           %{identity: channel.id, data: channel},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec delete(
          channel :: Payloads.Channel.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(channel, _ws_state, context) do
    case Handler.invoke_configured_action(
           :CHANNEL_DELETE,
           %{discord_id: channel.id},
           %{},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
