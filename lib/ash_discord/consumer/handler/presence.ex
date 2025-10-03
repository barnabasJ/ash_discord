defmodule AshDiscord.Consumer.Handler.Presence do
  @spec update(
          consumer :: module(),
          new_presence ::
            {guild_id :: integer(),
             {old_presence :: Nostrum.Struct.Presence.t(),
              new_presence :: Nostrum.Struct.Presence.t()}},
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def update(_consumer, {_guild_id, _old_presence, _new_presence}, _ws_state, _context) do
    :ok
  end
end
