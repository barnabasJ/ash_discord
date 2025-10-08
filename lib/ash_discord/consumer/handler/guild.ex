defmodule AshDiscord.Consumer.Handler.Guild do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec create(
          new_guild :: Payloads.Guild.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: {:ok, Ash.Resource.record()} | {:error, term()}
  def create(guild, _ws_state, context) do
    register_commands(context.consumer, guild)

    Handler.invoke_configured_action(
      :GUILD_CREATE,
      %{discord_id: guild.id},
      %{identity: guild.id, data: guild},
      context
    )
  end

  defp register_commands(consumer, guild) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_domains(consumer) do
      {:ok, domains} ->
        commands = AshDiscord.Consumer.collect_commands(domains)

        guild_commands =
          commands
          |> Enum.filter(&(&1.scope == :guild))
          |> Enum.map(&AshDiscord.Consumer.to_discord_command/1)

        case Nostrum.Api.ApplicationCommand.bulk_overwrite_guild_commands(
               guild.id,
               guild_commands
             ) do
          {:ok, _} ->
            Logger.info("Registered #{length(guild_commands)} guild command(s) for #{guild.name}")

          {:error, error} ->
            Logger.error("Failed to register guild commands for #{guild.name}: #{inspect(error)}")
        end

      _ ->
        :ok
    end
  end

  @spec update(
          guild_update :: Payloads.GuildUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.GuildUpdate{new_guild: new_guild}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :GUILD_UPDATE,
           %{discord_id: new_guild.id},
           %{identity: new_guild.id, data: new_guild},
           context
         ) do
      {:ok, _guild} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec delete(
          guild_delete :: Payloads.GuildDelete.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(
        %Payloads.GuildDelete{old_guild: old_guild, unavailable: unavailable},
        _ws_state,
        context
      ) do
    case unavailable do
      unavailable when unavailable in [nil, false] ->
        Handler.invoke_configured_action(
          :GUILD_DELETE,
          %{discord_id: old_guild.id},
          %{},
          context
        )

      true ->
        # Temporary unavailability - guild still exists but bot can't access it
        Logger.info("Guild #{old_guild.id} became unavailable (temporary)")
        :ok
    end
  end

  @spec available(
          guild :: Payloads.Guild.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: {:ok, Ash.Resource.record()} | {:error, term()}
  def available(guild, ws_state, context) do
    # When a guild becomes available, treat it like a create
    create(guild, ws_state, context)

    Handler.invoke_configured_action(
      :GUILD_AVAILABLE,
      %{discord_id: guild.id},
      %{identity: guild.id, data: guild},
      context
    )
  end

  @spec unavailable(
          guild :: Payloads.Guild.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok
  def unavailable(guild, _ws_state, context) do
    case Handler.invoke_configured_action(
           :GUILD_UNAVAILABLE,
           %{discord_id: guild.id},
           %{identity: guild.id, data: guild},
           context
         ) do
      {:ok, _guild} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
