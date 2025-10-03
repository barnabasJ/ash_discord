defmodule AshDiscord.Consumer.Handler.Guild.Audit.Log.Entry do
  @spec create(
          consumer :: module(),
          entry :: Nostrum.Struct.Guild.AuditLogEntry.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def create(_consumer, _entry, _ws_state, _context), do: :ok
end
