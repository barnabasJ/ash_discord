defmodule AshDiscord.Consumer.Handler.Webhooks do
  @spec update(
          consumer :: module(),
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def update(_consumer, _data, _ws_state, _context), do: :ok
end
