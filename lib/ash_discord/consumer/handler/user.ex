defmodule AshDiscord.Consumer.Handler.User do
  alias AshDiscord.Consumer.Payloads

  @spec update(
          user_update :: Payloads.UserUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(_user_update, _ws_state, _context) do
    # TODO: Implement user update logic when user resource is configured
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
