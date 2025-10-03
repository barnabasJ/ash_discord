defmodule AshDiscord.Consumer.Handler.Channel.Pins do
  @spec ack(
          consumer :: module(),
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def ack(_consumer, _data, _ws_state), do: :ok

  @spec update(
          consumer :: module(),
          data :: Nostrum.Struct.Event.ChannelPinsUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def update(_consumer, _data, _ws_state), do: :ok
end
