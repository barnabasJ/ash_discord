defmodule AshDiscord.Consumer.Handler.Channel.Pins do
  @spec ack(
          consumer :: module(),
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def ack(_consumer, _data, _ws_state, _context), do: :ok

  @spec update(
          consumer :: module(),
          data :: Nostrum.Struct.Event.ChannelPinsUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def update(_consumer, _data, _ws_state, _context), do: :ok
end
