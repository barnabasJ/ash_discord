defmodule AshDiscord.Consumer.Handler.Interaction do
  require Logger

  @spec create(
          consumer :: module(),
          interaction :: Nostrum.Struct.Interaction.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: any()
  def create(consumer, interaction, _ws_state, _context) do
    Logger.debug("Processing Discord interaction: #{interaction.id}")

    case interaction.type do
      # Application command
      2 ->
        handle_application_command(consumer, interaction)

      # Other interaction types (buttons, select menus, etc.)
      _ ->
        :ok
    end
  end

  defp handle_application_command(consumer, interaction) do
    command_name = String.to_existing_atom(interaction.data.name)
    Logger.info("Processing slash command: #{command_name} from user #{interaction.user.id}")

    case find_command(consumer, command_name) do
      nil ->
        Logger.error("Unknown command: #{command_name}")
        respond_with_error(interaction, "Unknown command")

      command ->
        # Apply command filtering based on guild context
        if command_allowed_for_interaction?(consumer, interaction, command) do
          AshDiscord.InteractionRouter.route_interaction(interaction, command, consumer: consumer)
        else
          Logger.warning("Command #{command_name} filtered for guild #{interaction.guild_id}")
          respond_with_error(interaction, "This command is not available in this server")
        end
    end
  end

  defp find_command(consumer, command_name) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_domains(consumer) do
      {:ok, domains} ->
        commands = AshDiscord.Consumer.collect_commands(domains)
        Enum.find(commands, &(&1.name == command_name))

      _ ->
        nil
    end
  end

  defp command_allowed_for_interaction?(consumer, interaction, command) do
    case AshDiscord.Consumer.Info.ash_discord_consumer_command_filter(consumer) do
      {:ok, filter} when not is_nil(filter) ->
        guild = extract_guild_context(interaction)
        # TODO: we should make the params (command, guild_id, user) if all we have
        # is the guild_id
        filter.command_allowed?(command, guild)

      _ ->
        true
    end
  end

  defp extract_guild_context(interaction) do
    case interaction.guild_id do
      nil -> nil
      guild_id -> %{id: guild_id}
    end
  end

  defp respond_with_error(interaction, message) do
    response = %{
      # CHANNEL_MESSAGE_WITH_SOURCE
      type: 4,
      data: %{
        content: message,
        # EPHEMERAL
        flags: 64
      }
    }

    case Nostrum.Api.create_interaction_response(interaction, response) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.error("Failed to send error response: #{inspect(error)}")
        :ok
    end
  end
end
