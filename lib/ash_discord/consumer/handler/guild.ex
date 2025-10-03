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
  def update(consumer, {_old_guild, new_guild}, _ws_state) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_guild_resource(consumer) do
      {:ok, guild_resource} ->
        case guild_resource
             |> Ash.Changeset.for_create(:from_discord, %{
               discord_id: new_guild.id,
               discord_struct: new_guild
             })
             |> Ash.Changeset.set_context(%{
               private: %{ash_discord?: true},
               shared: %{private: %{ash_discord?: true}}
             })
             |> Ash.create() do
          {:ok, _guild_record} ->
            :ok

          {:error, error} ->
            Logger.error(
              "Failed to update guild #{new_guild.name} (#{new_guild.id}): #{inspect(error)}"
            )

            # Don't crash the consumer
            :ok
        end

      :error ->
        # No guild resource configured
        :ok
    end
  end

  @spec delete(
          consumer :: module(),
          {
            old_guild :: Nostrum.Struct.Guild.t(),
            unavailable :: boolean()
          },
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def delete(consumer, {old_guild, unavailable}, _ws_state) do
    Logger.debug(
      "AshDiscord: handle_guild_delete called with data: #{inspect({old_guild, unavailable})}"
    )

    case AshDiscord.Consumer.Info.ash_discord_consumer_guild_resource(consumer) do
      {:ok, resource} ->
        Logger.info("AshDiscord: Guild resource found: #{inspect(resource)}")

        case unavailable do
          unavailable when unavailable in [nil, false] ->
            # Permanent deletion - unavailable=nil or false means guild was actually deleted
            guild_discord_id = old_guild.id
            Logger.info("AshDiscord: Deleting guild #{guild_discord_id} (permanent removal)")

            case resource
                 |> Ash.Query.for_read(:read)
                 |> Ash.Query.filter(discord_id: guild_discord_id)
                 |> Ash.Query.set_context(%{
                   private: %{ash_discord?: true},
                   shared: %{private: %{ash_discord?: true}}
                 })
                 |> Ash.read() do
              {:ok, [guild]} ->
                Logger.info("AshDiscord: Found guild to delete: #{inspect(guild)}")

                case guild |> Ash.destroy(actor: %{role: :bot}) do
                  :ok ->
                    Logger.info("AshDiscord: Guild #{guild_discord_id} deleted successfully")
                    :ok

                  {:error, error} ->
                    Logger.error(
                      "AshDiscord: Failed to delete guild #{guild_discord_id}: #{inspect(error)}"
                    )

                    :ok
                end

              {:ok, []} ->
                Logger.info("AshDiscord: Guild #{guild_discord_id} not found, nothing to delete")

                :ok

              {:error, error} ->
                Logger.error(
                  "AshDiscord: Failed to find guild #{guild_discord_id} for deletion: #{inspect(error)}"
                )

                :ok
            end

          true ->
            # Temporary unavailability - guild still exists but bot can't access it
            Logger.info("AshDiscord: Guild #{old_guild.id} became unavailable (temporary)")
            :ok
        end

      :error ->
        Logger.info("AshDiscord: No guild resource configured")
        :ok
    end
  end

  @spec available(
          consumer :: module(),
          new_guild :: Nostrum.Struct.Guild.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def available(consumer, guild, _ws_state) do
    # When a guild becomes available, treat it like a create
    create(consumer, guild, nil)
  end

  @spec unavailable(
          consumer :: module(),
          unavailable_guild :: Nostrum.Struct.Guild.UnavailableGuild.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def unavailable(_consumer, _guild, _ws_state) do
    :ok
  end

  defp resource(consumer) do
    AshDiscord.Consumer.Info.ash_discord_consumer_guild_resource!(consumer)
  end
end
