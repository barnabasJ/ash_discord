defmodule AshDiscord.Consumer.Handler.Guild.Members do
  @spec chunk(
          consumer :: module(),
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def chunk(_consumer, _data, _ws_state), do: :ok
end
