defmodule AshDiscord.Consumer.Handler.Guild.Ban do
  require Ash.Query
  require Logger

  alias AshDiscord.Consumer.Payloads

  @spec add(
          ban_add :: Payloads.GuildBanAddEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def add(%Payloads.GuildBanAddEvent{guild_id: guild_id, user: user}, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{
      data: %{guild_id: guild_id, user: user}
    })
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _ban_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec remove(
          ban_remove :: Payloads.GuildBanRemoveEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def remove(%Payloads.GuildBanRemoveEvent{guild_id: guild_id, user: user}, _ws_state, context) do
    query =
      context.resource
      |> Ash.Query.filter(discord_id == ^user.id and guild_id == ^guild_id)

    case Ash.bulk_destroy(query, :destroy, %{},
           context: %{
             private: %{ash_discord?: true},
             shared: %{private: %{ash_discord?: true}}
           }
         ) do
      %Ash.BulkResult{status: :success} ->
        :ok

      result ->
        {:error, result}
    end
  end
end
