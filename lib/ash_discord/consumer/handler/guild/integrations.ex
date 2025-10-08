defmodule AshDiscord.Consumer.Handler.Guild.Integrations do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @moduledoc """
  Handler for GUILD_INTEGRATIONS_UPDATE events.

  Note: This event only contains the guild_id and indicates that integrations
  were updated. Discord does not send the actual integration data in this event.
  If you need the integration data, you must fetch it separately using the
  Discord API.
  """

  @spec update(
          integrations_update :: Payloads.GuildIntegrationsUpdateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(
        %Payloads.GuildIntegrationsUpdateEvent{guild_id: guild_id} = event,
        _ws_state,
        context
      ) do
    # This event only notifies that integrations were updated for a guild
    # It does not contain the actual integration data
    Logger.debug("Guild integrations updated for guild_id: #{guild_id}")

    case Handler.invoke_configured_action(
           :GUILD_INTEGRATIONS_UPDATE,
           guild_id,
           %{guild_id: guild_id, data: event},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
