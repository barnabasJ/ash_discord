defmodule AshDiscord.Consumer.Handler.Thread do
  @spec create(
          consumer :: module(),
          thread :: Nostrum.Struct.Channel.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def create(_consumer, _thread, _ws_state, _context), do: :ok

  @spec delete(
          consumer :: module(),
          thread :: Nostrum.Struct.Channel.t() | :noop,
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def delete(_consumer, _thread, _ws_state, _context), do: :ok

  @spec update(
          consumer :: module(),
          data ::
            {old_thread :: Nostrum.Struct.Channel.t() | nil,
             new_thread :: Nostrum.Struct.Channel.t()},
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def update(_consumer, _data, _ws_state, _context), do: :ok

  @spec list(
          consumer :: module(),
          data :: Nostrum.Struct.Event.ThreadListSync.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def list(_consumer, _data, _ws_state, _context), do: :ok
end
