defmodule AshDiscord.Consumer.Handler.Guild.Audit.Log.Entry do
  alias AshDiscord.Consumer.Payloads

  @spec create(
          entry :: Payloads.GuildAuditLogEntryCreateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(%Payloads.GuildAuditLogEntryCreateEvent{} = entry, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: entry})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _audit_log_entry} -> :ok
      {:error, _error} = error -> error
    end
  end
end
