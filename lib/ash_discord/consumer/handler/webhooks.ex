defmodule AshDiscord.Consumer.Handler.Webhooks do
  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec update(
          webhooks_update_event :: Payloads.WebhooksUpdateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(webhooks_update, _ws_state, context) do
    case Handler.invoke_configured_action(
           :WEBHOOKS_UPDATE,
           %{guild_id: webhooks_update.guild_id, channel_id: webhooks_update.channel_id},
           %{data: webhooks_update},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end
end
