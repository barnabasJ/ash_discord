defmodule AshDiscord.Consumer.Handler.User do
  @spec update(
          {old_user :: Nostrum.Struct.User.t() | nil, new_user :: Nostrum.Struct.User.t()},
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(_user_data, _ws_state, _context) do
    :ok
  end

  @spec settings(
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def settings(_data, _ws_state, _context) do
    :ok
  end
end
