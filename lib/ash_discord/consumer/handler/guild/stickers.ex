defmodule AshDiscord.Consumer.Handler.Guild.Stickers do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec update(
          stickers_update :: Payloads.GuildStickersUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(
        %Payloads.GuildStickersUpdate{guild_id: _guild_id, new_stickers: stickers},
        _ws_state,
        context
      ) do
    # Process each sticker in the new_stickers list
    # TODO: make the handler accept a list of stickers to reduce the number of calls
    results =
      Enum.map(stickers, fn sticker ->
        Handler.invoke_configured_action(
          :GUILD_STICKERS_UPDATE,
          %{discord_id: sticker.id},
          %{
            data: sticker,
            identity: sticker.id
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
