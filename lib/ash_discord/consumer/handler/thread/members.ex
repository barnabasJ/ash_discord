defmodule AshDiscord.Consumer.Handler.Thread.Members do
  @spec update(
          consumer :: module(),
          data :: Nostrum.Struct.Event.ThreadMembersUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def update(_consumer, _data, _ws_state, _context), do: :ok
end
