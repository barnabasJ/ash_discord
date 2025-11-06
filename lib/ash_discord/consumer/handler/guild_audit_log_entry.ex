defmodule AshDiscord.Consumer.Handler.GuildAuditLogEntry do
  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec create(
          entry :: Payloads.GuildAuditLogEntryCreateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(%Payloads.GuildAuditLogEntryCreateEvent{} = entry, _ws_state, context) do
    case Handler.invoke_configured_action(
           :GUILD_AUDIT_LOG_ENTRY_CREATE,
           %{discord_id: entry.id},
           %{data: entry},
           context
         ) do
      {:ok, _audit_log_entry} -> :ok
      {:error, _error} = error -> error
    end
  end
end
