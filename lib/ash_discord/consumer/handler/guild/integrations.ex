defmodule AshDiscord.Consumer.Handler.Guild.Integrations do
  @spec update(
          consumer :: module(),
          data :: Nostrum.Struct.Event.GuildIntegrationsUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def update(_consumer, _data, _ws_state, _context), do: :ok
end
