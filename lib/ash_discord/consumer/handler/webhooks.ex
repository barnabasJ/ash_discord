defmodule AshDiscord.Consumer.Handler.Webhooks do
  @spec update(
          consumer :: module(),
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def update(_consumer, _data, _ws_state), do: :ok
end
