defmodule AshDiscord.Consumer.Handler.Thread.Member do
  require Logger

  alias AshDiscord.Consumer.Payloads

  @spec update(
          member :: Payloads.ThreadMember.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(member, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: member})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _member_record} -> :ok
      {:error, _error} = error -> error
    end
  end
end
