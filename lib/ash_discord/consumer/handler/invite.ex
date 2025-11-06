defmodule AshDiscord.Consumer.Handler.Invite do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec create(
          consumer :: module(),
          invite_create :: Payloads.InviteCreateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(_consumer, invite, _ws_state, context) do
    case Handler.invoke_configured_action(
           :INVITE_CREATE,
           %{code: invite.code},
           %{data: invite},
           context
         ) do
      {:ok, _} ->
        Logger.info("AshDiscord: Invite created successfully")
        :ok

      {:error, error} ->
        Logger.error("AshDiscord: Failed to create invite: #{inspect(error)}")
        :ok
    end
  end

  @spec delete(
          consumer :: module(),
          invite_delete :: Payloads.InviteDeleteEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(_consumer, invite_delete, _ws_state, context) do
    case Handler.invoke_configured_action(
           :INVITE_DELETE,
           %{code: invite_delete.code},
           %{},
           context
         ) do
      {:ok, nil} ->
        Logger.warning("AshDiscord: Invite not found for deletion: #{invite_delete.code}")
        :ok

      {:ok, _} ->
        Logger.info("AshDiscord: Invite deleted successfully")
        :ok

      {:error, error} ->
        Logger.error("AshDiscord: Failed to delete invite: #{inspect(error)}")
        :ok
    end
  end
end
