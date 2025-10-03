defmodule AshDiscord.Consumer.Handler.Guild.Stickers do
  @spec update(
          consumer :: module(),
          data ::
            {guild_id :: integer(), old_stickers :: [Nostrum.Struct.Sticker.t()],
             new_stickers :: [Nostrum.Struct.Sticker.t()]},
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def update(_consumer, _data, _ws_state), do: :ok
end
