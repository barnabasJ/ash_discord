defmodule AshDiscord.Consumer.Handler.Guild.Emojis do
  require Ash.Query
  require Logger

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
    # Process each emoji in the new_emojis list
    results =
      Enum.map(emojis, fn emoji ->
        context.resource
        |> Ash.Changeset.for_create(:from_discord, %{
          data: emoji,
          identity: %{emoji_id: emoji.id, guild_id: guild_id}
        })
        |> Ash.Changeset.set_context(%{
          private: %{ash_discord?: true},
          shared: %{private: %{ash_discord?: true}}
        })
        |> Ash.create()
      end)

    # Check if any failed
    case Enum.find(results, fn result -> match?({:error, _}, result) end) do
      nil -> :ok
      {:error, _error} = error -> error
    end
  end
end
