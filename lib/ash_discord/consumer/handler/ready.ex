defmodule AshDiscord.Consumer.Handler.Ready do
  alias AshDiscord.Consumer.Handler

  require Logger

  @spec ready(
          data :: AshDiscord.Consumer.Payloads.ReadyEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def ready(data, _ws_state, context) do
    # Register Discord commands when bot is ready
    with {:ok, domains} <- AshDiscord.Consumer.Info.ash_discord_consumer_domains(context.consumer) do
      commands = AshDiscord.Consumer.collect_commands(domains)

      # Filter by scope and register appropriately
      global_commands =
        commands
        |> Enum.filter(&(&1.scope == :global))
        |> Enum.map(&AshDiscord.Consumer.to_discord_command/1)

      # Register global commands
      if length(global_commands) > 0 do
        case Nostrum.Api.ApplicationCommand.bulk_overwrite_global_commands(global_commands) do
          {:ok, _} ->
            Logger.info("Registered #{length(global_commands)} global command(s)")

          {:error, error} ->
            Logger.error("Failed to register global commands: #{inspect(error)}")
        end
      end
    end

    Handler.invoke_configured_action(
      :READY,
      nil,
      %{data: data},
      context
    )
  end
end
