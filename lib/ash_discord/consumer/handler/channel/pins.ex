defmodule AshDiscord.Consumer.Handler.Channel.Pins do
  alias AshDiscord.Consumer.Payloads

  @spec update(
          channel_pins_update :: Payloads.ChannelPinsUpdateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(channel_pins_update, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: channel_pins_update})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _pins_record} -> :ok
      {:error, _error} = error -> error
    end
  end
end
