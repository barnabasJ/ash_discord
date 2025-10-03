defmodule AshDiscord.Consumer.Handler.Guild do
  @spec create(
          consumer :: module(),
          new_guild :: Nostrum.Struct.Guild.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def create(consumer, guild, _ws_state) do
    register_commands(consumer, guild)

    resource(consumer)
    |> Ash.Changeset.for_create(:from_discord, %{
      discord_id: guild.id,
      discord_struct: guild
    })
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
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
          consumer :: module(),
          {
            old_guild :: Nostrum.Struct.Guild.t(),
            new_guild :: Nostrum.Struct.Guild.t()
          },
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def update(consumer, {old_guild, new_guild}, _ws_state) do
    :ok
  end

  @spec unavailable(
          consumer :: module(),
          unavailable_guild :: Nostrum.Struct.Guild.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def unavailable(consumer, guild, _ws_state) do
    :ok
  end

  defp resource(consumer) do
    AshDiscord.Consumer.Info.ash_discord_consumer_guild_resource!(consumer)
  end
end
