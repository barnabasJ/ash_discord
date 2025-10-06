defmodule AshDiscord.Consumer.Handler.Webhooks do
  alias AshDiscord.Consumer.Payloads

  @spec update(
          webhooks_update_event :: Payloads.WebhooksUpdateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(webhooks_update, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: webhooks_update})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _webhooks_update_record} -> :ok
      {:error, _error} = error -> error
    end
  end
end
