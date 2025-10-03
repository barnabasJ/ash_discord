defmodule AshDiscord.Consumer.Handler.User do
  @spec update(
          consumer :: module(),
          {old_user :: Nostrum.Struct.User.t() | nil, new_user :: Nostrum.Struct.User.t()},
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def update(_consumer, _user_data, _ws_state, _context) do
    :ok
  end

  @spec settings(
          consumer :: module(),
          data :: no_return(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def settings(_consumer, _data, _ws_state, _context) do
    :ok
  end
end
