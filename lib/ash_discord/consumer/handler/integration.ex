defmodule AshDiscord.Consumer.Handler.Integration do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec create(
          integration :: Payloads.Integration.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(%Payloads.Integration{} = integration, _ws_state, context) do
    case Handler.invoke_configured_action(
           :INTEGRATION_CREATE,
           %{integration_id: integration.id, guild_id: integration.guild_id},
           %{data: integration},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec update(
          integration :: Payloads.Integration.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.Integration{} = integration, _ws_state, context) do
    case Handler.invoke_configured_action(
           :INTEGRATION_UPDATE,
           %{integration_id: integration.id, guild_id: integration.guild_id},
           %{data: integration},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec delete(
          integration_delete :: Payloads.IntegrationDelete.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(%Payloads.IntegrationDelete{} = integration_delete, _ws_state, context) do
    case Handler.invoke_configured_action(
           :INTEGRATION_DELETE,
           %{discord_id: integration_delete.id, guild_discord_id: integration_delete.guild_id},
           %{},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end
end
