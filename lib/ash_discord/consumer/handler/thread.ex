defmodule AshDiscord.Consumer.Handler.Thread do
  require Ash.Query
  require Logger

  alias AshDiscord.Consumer.Payloads

  @spec create(
          thread :: Payloads.Thread.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(thread, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: thread})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _thread_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec delete(
          thread :: Payloads.ThreadDelete.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(thread, _ws_state, context) do
    query =
      context.resource
      |> Ash.Query.filter(discord_id == ^thread.id)

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

  @spec update(
          thread_update :: Payloads.ThreadUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.ThreadUpdate{new_thread: thread}, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: thread})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _thread_record} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec list_sync(
          sync_event :: Payloads.ThreadListSyncEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def list_sync(sync_event, _ws_state, context) do
    context.resource
    |> Ash.Changeset.for_create(:from_discord, %{data: sync_event})
    |> Ash.Changeset.set_context(%{
      private: %{ash_discord?: true},
      shared: %{private: %{ash_discord?: true}}
    })
    |> Ash.create()
    |> case do
      {:ok, _sync_record} -> :ok
      {:error, _error} = error -> error
    end
  end
end
