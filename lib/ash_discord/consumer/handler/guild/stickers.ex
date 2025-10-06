defmodule AshDiscord.Consumer.Handler.Guild.Stickers do
  require Ash.Query
  require Logger

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
    results =
      Enum.map(stickers, fn sticker ->
        context.resource
        |> Ash.Changeset.for_create(:from_discord, %{
          data: sticker,
          identity: sticker.id
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
