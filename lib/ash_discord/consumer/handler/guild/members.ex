defmodule AshDiscord.Consumer.Handler.Guild.Members do
  @spec chunk(
          consumer :: module(),
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def chunk(_consumer, _data, _ws_state, _context), do: :ok
end
