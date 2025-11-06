defmodule AshDiscord.Consumer.Handler.GuildBan do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec add(
          ban_add :: Payloads.GuildBanAddEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def add(%Payloads.GuildBanAddEvent{guild_id: guild_id, user: user}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :GUILD_BAN_ADD,
           user.id,
           %{data: %{guild_id: guild_id, user: user}},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec remove(
          ban_remove :: Payloads.GuildBanRemoveEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def remove(%Payloads.GuildBanRemoveEvent{guild_id: guild_id, user: user}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :GUILD_BAN_REMOVE,
           %{user_discord_id: user.id, guild_discord_id: guild_id},
           %{},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end
end
