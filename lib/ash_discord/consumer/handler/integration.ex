defmodule AshDiscord.Consumer.Handler.Integration do
  require Ash.Query
  require Logger

  alias AshDiscord.Consumer.Payloads

  @spec create(
          integration :: Payloads.Integration.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(%Payloads.Integration{} = integration, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{
      data: integration,
      identity: %{integration_id: integration.id, guild_id: integration.guild_id}
    })
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _integration_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec update(
          integration :: Payloads.Integration.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.Integration{} = integration, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{
      data: integration,
      identity: %{integration_id: integration.id, guild_id: integration.guild_id}
    })
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _integration_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec delete(
          integration_delete :: Payloads.IntegrationDelete.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(%Payloads.IntegrationDelete{} = integration_delete, _ws_state, context) do
    query =
      context.resource
      |> Ash.Query.filter(
        discord_id == ^integration_delete.id and guild_id == ^integration_delete.guild_id
      )

    case Ash.bulk_destroy(query, :destroy, %{},
           context: %{
             private: %{ash_discord?: true},
             shared: %{private: %{ash_discord?: true}}
           }
         ) do
      %Ash.BulkResult{status: :success} ->
        :ok

      result ->
        {:error, result}
    end
  end
end
