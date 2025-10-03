defmodule AshDiscord.Consumer.Handler.Guild.Role do
  require Logger

  @spec create(
          consumer :: module(),
          {guild_id :: integer(), new_role :: Nostrum.Struct.Guild.Role.t()},
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def create(consumer, {guild_id, role}, _ws_state, _context) do
    with {:ok, resource} <-
           AshDiscord.Consumer.Info.ash_discord_consumer_role_resource(consumer),
         {:ok, _role} <-
           resource
           |> Ash.Changeset.for_create(
             :from_discord,
             %{
               discord_id: role.id,
               guild_discord_id: guild_id,
               discord_struct: role
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
          {guild_id :: integer(), old_role :: Nostrum.Struct.Guild.Role.t() | nil,
           new_role :: Nostrum.Struct.Guild.Role.t()},
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def update(consumer, {guild_id, _old_role, role}, _ws_state, _context) do
    Logger.debug("AshDiscord: Handling guild role update for role #{role.id}")

    with {:ok, resource} <-
           AshDiscord.Consumer.Info.ash_discord_consumer_role_resource(consumer),
         {:ok, _role} <-
           resource
           |> Ash.Changeset.for_create(
             :from_discord,
             %{
               discord_id: role.id,
               guild_discord_id: guild_id,
               discord_struct: role
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
          {guild_id :: integer(), old_role :: Nostrum.Struct.Guild.Role.t()},
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Consumer.Context.t()
        ) :: any()
  def delete(_consumer, _data, _ws_state, _context) do
    # Role deletion not yet implemented
    # TODO: Implement role deletion when needed
    :ok
  end
end
