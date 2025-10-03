defmodule AshDiscord.Consumer.Handler.Resumed do
  @spec resumed(
          consumer :: module(),
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def resumed(_consumer, _data, _ws_state, _context), do: :ok
end
