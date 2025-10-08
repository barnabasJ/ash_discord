defmodule AshDiscord.Consumer.Handler.Presence do
  alias AshDiscord.Consumer.Handler

  @spec update(
          new_presence :: AshDiscord.Consumer.Payload.presence_update(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update({guild_id, old_presence, new_presence}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :PRESENCE_UPDATE,
           %{user_discord_id: new_presence.user.id, guild_discord_id: guild_id},
           %{guild_id: guild_id, old_presence: old_presence, new_presence: new_presence},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
