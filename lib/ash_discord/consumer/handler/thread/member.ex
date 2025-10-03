defmodule AshDiscord.Consumer.Handler.Thread.Member do
  @spec update(
          consumer :: module(),
          member :: Nostrum.Struct.ThreadMember.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def update(_consumer, _member, _ws_state), do: :ok
end
