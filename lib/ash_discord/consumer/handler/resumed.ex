defmodule AshDiscord.Consumer.Handler.Resumed do
  @spec resumed(
          consumer :: module(),
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def resumed(_consumer, _data, _ws_state), do: :ok
end
