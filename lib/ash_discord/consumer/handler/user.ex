defmodule AshDiscord.Consumer.Handler.User do
  @spec update(
          consumer :: module(),
          new_presence ::
            {guild_id :: integer(),
             {old_presence :: Nostrum.Struct.Presence.t(),
              new_presence :: Nostrum.Struct.Presence.t()}},
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def update(_consumer, _user, _ws_state) do
    :ok
  end
end
