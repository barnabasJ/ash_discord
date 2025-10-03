defmodule AshDiscord.Consumer.Handler.Message.Poll.Vote do
  @spec add(
          consumer :: module(),
          data :: Nostrum.Struct.Event.PollVoteChange.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def add(_consumer, _data, _ws_state, _context) do
    :ok
  end

  @spec remove(
          consumer :: module(),
          data :: Nostrum.Struct.Event.PollVoteChange.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def remove(_consumer, _data, _ws_state, _context) do
    :ok
  end
end
