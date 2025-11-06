defmodule AshDiscord.Consumer.Handler.User do
  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec update(
          user_update :: Payloads.UserUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.UserUpdate{new_user: new_user}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :USER_UPDATE,
           new_user.id,
           %{identity: new_user.id, data: new_user},
           context
         ) do
      {:ok, _user} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec settings(
          data :: map(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def settings(data, _ws_state, context) do
    case Handler.invoke_configured_action(
           :USER_SETTINGS_UPDATE,
           %{},
           %{data: data},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
