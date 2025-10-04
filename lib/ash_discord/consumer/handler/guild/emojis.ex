defmodule AshDiscord.Consumer.Handler.Guild.Emojis do
  @spec update(
          consumer :: module(),
          data ::
            {guild_id :: integer(), old_emojis :: [Nostrum.Struct.Emoji.t()],
             new_emojis :: [Nostrum.Struct.Emoji.t()]},
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(_consumer, _data, _ws_state, _context), do: :ok
end
