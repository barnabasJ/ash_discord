defmodule AshDiscord.Consumer.Handler.Guild.Emojis do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec update(
          emojis_update :: Payloads.GuildEmojisUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(
        %Payloads.GuildEmojisUpdate{guild_id: guild_id, new_emojis: emojis},
        _ws_state,
        context
      ) do
    # Process all emojis in a single bulk operation
    # For each emoji, we need to call invoke_configured_action
    results =
      Enum.map(emojis, fn emoji ->
        Handler.invoke_configured_action(
          :GUILD_EMOJIS_UPDATE,
          emoji.id,
          %{
            data: emoji,
            identity: %{emoji_id: emoji.id, guild_id: guild_id}
          },
          context
        )
      end)

    # Check if any failed
    case Enum.find(results, fn result -> match?({:error, _}, result) end) do
      nil -> :ok
      {:error, _error} = error -> error
    end
  end
end
