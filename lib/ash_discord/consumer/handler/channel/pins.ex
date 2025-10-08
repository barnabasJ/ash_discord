defmodule AshDiscord.Consumer.Handler.Channel.Pins do
  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec update(
          channel_pins_update :: Payloads.ChannelPinsUpdateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(channel_pins_update, _ws_state, context) do
    case Handler.invoke_configured_action(
           :CHANNEL_PINS_UPDATE,
           channel_pins_update.channel_id,
           %{data: channel_pins_update},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
