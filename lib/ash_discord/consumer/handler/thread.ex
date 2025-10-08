defmodule AshDiscord.Consumer.Handler.Thread do
  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec create(
          thread :: Payloads.Thread.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(thread, _ws_state, context) do
    case Handler.invoke_configured_action(
           :THREAD_CREATE,
           %{discord_id: thread.id},
           %{identity: thread.id, data: thread},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec delete(
          thread :: Payloads.ThreadDelete.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(thread, _ws_state, context) do
    case Handler.invoke_configured_action(
           :THREAD_DELETE,
           %{discord_id: thread.id},
           %{},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec update(
          thread_update :: Payloads.ThreadUpdate.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(%Payloads.ThreadUpdate{new_thread: thread}, _ws_state, context) do
    case Handler.invoke_configured_action(
           :THREAD_UPDATE,
           %{discord_id: thread.id},
           %{identity: thread.id, data: thread},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec list_sync(
          sync_event :: Payloads.ThreadListSyncEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def list_sync(sync_event, _ws_state, context) do
    case Handler.invoke_configured_action(
           :THREAD_LIST_SYNC,
           %{discord_id: sync_event.id},
           %{identity: sync_event.id, data: sync_event},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec member_update(
          member :: Payloads.ThreadMember.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def member_update(member, _ws_state, context) do
    case Handler.invoke_configured_action(
           :THREAD_MEMBER_UPDATE,
           %{id: member.id, user_id: member.user_id},
           %{data: member},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end

  @spec members_update(
          members_update :: Payloads.ThreadMembersUpdateEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def members_update(members_update, _ws_state, context) do
    case Handler.invoke_configured_action(
           :THREAD_MEMBERS_UPDATE,
           %{id: members_update.id},
           %{data: members_update},
           context
         ) do
      {:ok, _} -> :ok
      {:error, _error} = error -> error
    end
  end
end
