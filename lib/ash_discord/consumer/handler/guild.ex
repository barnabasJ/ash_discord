defmodule AshDiscord.Consumer.Handler.Guild do
  require Logger
  require Ash.Query

  alias AshDiscord.Consumer.Payloads

  @spec create(
          new_guild :: Payloads.Guild.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: {:ok, Ash.Resource.record()} | {:error, term()}
  def create(guild, _ws_state, context) do
    register_commands(context.consumer, guild)

    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{
      data: guild
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
          guild_update :: Payloads.GuildUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.GuildUpdate{new_guild: new_guild}, _ws_state, context) do
    case context.resource
         |> Ash.Changeset.for_create(:from_discord, %{
           data: new_guild
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

        {:error, error}
    end
  end

  @spec delete(
          guild_delete :: Payloads.GuildDelete.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(%Payloads.GuildDelete{old_guild: old_guild, unavailable: unavailable}, _ws_state, context) do
    case unavailable do
      unavailable when unavailable in [nil, false] ->
        # Permanent deletion - unavailable=nil or false means guild was actually deleted
        guild_discord_id = old_guild.id

        case context.resource
             |> Ash.Query.for_read(:read)
             |> Ash.Query.filter(discord_id == ^guild_discord_id)
             |> Ash.Query.set_context(%{
               private: %{ash_discord?: true},
               shared: %{private: %{ash_discord?: true}}
             })
             |> Ash.read() do
          {:ok, [guild]} ->
            case guild |> Ash.destroy(actor: %{role: :bot}) do
              :ok -> :ok
              {:error, error} -> {:error, error}
            end

          {:ok, []} ->
            Logger.info("Guild #{guild_discord_id} not found, nothing to delete")
            :ok

          {:error, error} ->
            Logger.error(
              "Failed to find guild #{guild_discord_id} for deletion: #{inspect(error)}"
            )

            {:error, error}
        end

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
  end

  @spec unavailable(
          guild :: Payloads.Guild.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok
  def unavailable(_guild, _ws_state, _context) do
    :ok
  end
end
