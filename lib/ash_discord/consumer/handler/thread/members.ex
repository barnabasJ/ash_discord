defmodule AshDiscord.Consumer.Handler.Thread.Members do
  require Logger

  alias AshDiscord.Consumer.Payloads

  @spec update(
          members_update :: Payloads.ThreadMembersUpdateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(members_update, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: members_update})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _update_record} -> :ok
      {:error, _error} = error -> error
    end
  end
end
