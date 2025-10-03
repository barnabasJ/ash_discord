defmodule AshDiscord.Consumer.Handler.Thread.Member do
  @spec update(
          consumer :: module(),
          member :: Nostrum.Struct.ThreadMember.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def update(_consumer, _member, _ws_state, _context), do: :ok
end
