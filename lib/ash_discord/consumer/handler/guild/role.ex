defmodule AshDiscord.Consumer.Handler.Guild.Role do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec create(
          role_create :: Payloads.GuildRoleCreate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(%Payloads.GuildRoleCreate{guild_id: guild_id, role: role}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :GUILD_ROLE_CREATE,
           %{discord_id: role.id, guild_id: guild_id},
           %{data: role, identity: %{role_id: role.id, guild_id: guild_id}},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec update(
          role_update :: Payloads.GuildRoleUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.GuildRoleUpdate{guild_id: guild_id, new_role: role}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :GUILD_ROLE_UPDATE,
           %{discord_id: role.id, guild_id: guild_id},
           %{data: role, identity: %{role_id: role.id, guild_id: guild_id}},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec delete(
          role_delete :: Payloads.GuildRoleDelete.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(%Payloads.GuildRoleDelete{guild_id: guild_id, role: role}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :GUILD_ROLE_DELETE,
           %{discord_id: role.id, guild_id: guild_id},
           %{},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
