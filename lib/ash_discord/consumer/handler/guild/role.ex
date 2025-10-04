defmodule AshDiscord.Consumer.Handler.Guild.Role do
  require Logger

  alias AshDiscord.Consumer.Payloads

  @spec create(
          consumer :: module(),
          role_create :: Payloads.GuildRoleCreate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(consumer, %Payloads.GuildRoleCreate{guild_id: guild_id, role: role}, _ws_state, _context) do
    with {:ok, resource} <-
           AshDiscord.Consumer.Info.ash_discord_consumer_role_resource(consumer),
         {:ok, _role} <-
           resource
           |> Ash.Changeset.for_create(
             :from_discord,
             %{
               data: role,
               identity: %{guild_id: guild_id}
             },
             context: %{
               private: %{ash_discord?: true},
               shared: %{private: %{ash_discord?: true}}
             }
           )
           |> Ash.create() do
      :ok
    else
      {:error, error} ->
        Logger.warning("Failed to create role #{role.id} in guild #{guild_id}: #{inspect(error)}")

        :ok

      :error ->
        # No role resource configured
        :ok
    end
  end

  @spec update(
          consumer :: module(),
          role_update :: Payloads.GuildRoleUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(consumer, %Payloads.GuildRoleUpdate{guild_id: guild_id, new_role: role}, _ws_state, _context) do
    Logger.debug("AshDiscord: Handling guild role update for role #{role.id}")

    with {:ok, resource} <-
           AshDiscord.Consumer.Info.ash_discord_consumer_role_resource(consumer),
         {:ok, _role} <-
           resource
           |> Ash.Changeset.for_create(
             :from_discord,
             %{
               data: role,
               identity: %{guild_id: guild_id}
             },
             context: %{
               private: %{ash_discord?: true},
               shared: %{private: %{ash_discord?: true}}
             }
           )
           |> Ash.create() do
      :ok
    else
      {:error, error} ->
        Logger.warning("Failed to update role #{role.id} in guild #{guild_id}: #{inspect(error)}")

        :ok

      :error ->
        # No role resource configured
        :ok
    end
  end

  @spec delete(
          consumer :: module(),
          role_delete :: Payloads.GuildRoleDelete.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(_consumer, _role_delete, _ws_state, _context) do
    # Role deletion not yet implemented
    # TODO: Implement role deletion when needed
    :ok
  end
end
