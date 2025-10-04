defmodule AshDiscord.Consumer.Handler.Guild.Role do
  require Ash.Query
  require Logger

  alias AshDiscord.Consumer.Payloads

  @spec create(
          role_create :: Payloads.GuildRoleCreate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(%Payloads.GuildRoleCreate{guild_id: guild_id, role: role}, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{
      data: role,
      identity: %{role_id: role.id, guild_id: guild_id}
    })
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _role_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec update(
          role_update :: Payloads.GuildRoleUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.GuildRoleUpdate{guild_id: guild_id, new_role: role}, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{
      data: role,
      identity: %{role_id: role.id, guild_id: guild_id}
    })
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _role_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec delete(
          role_delete :: Payloads.GuildRoleDelete.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(%Payloads.GuildRoleDelete{guild_id: guild_id, role: role}, _ws_state, context) do
    query =
      context.resource
      |> Ash.Query.filter(discord_id == ^role.id and guild_id == ^guild_id)

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
