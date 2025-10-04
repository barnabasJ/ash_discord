defmodule AshDiscord.Consumer.Handler.Presence do
  @spec update(
          new_presence :: AshDiscord.Consumer.Payload.presence_update(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update({_guild_id, _old_presence, _new_presence}, _ws_state, _context) do
    :ok
  end
end
