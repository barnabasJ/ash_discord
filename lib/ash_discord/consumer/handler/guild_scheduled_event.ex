defmodule AshDiscord.Consumer.Handler.GuildScheduledEvent do
  @moduledoc """
  Handler for Discord Guild Scheduled Event gateway events.

  Handles CREATE, UPDATE, DELETE, USER_ADD, and USER_REMOVE events for guild scheduled events.
  """

  require Logger

  alias AshDiscord.Consumer.Handler
  alias AshDiscord.Consumer.Payloads

  @spec create(
          consumer :: module(),
          event :: Payloads.GuildScheduledEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(
        _consumer,
        %Payloads.GuildScheduledEvent{id: event_id, guild_id: guild_id} = event,
        _ws_state,
        context
      ) do
    case Handler.invoke_configured_action(
           :GUILD_SCHEDULED_EVENT_CREATE,
           %{discord_id: event_id},
           %{data: event},
           context
         ) do
      {:ok, _scheduled_event} ->
        :ok

      {:error, error} ->
        Logger.warning(
          "Failed to create guild scheduled event #{event_id} in guild #{guild_id}: #{inspect(error)}"
        )

        :ok
    end
  end

  @spec update(
          consumer :: module(),
          event :: Payloads.GuildScheduledEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def update(
        _consumer,
        %Payloads.GuildScheduledEvent{id: event_id, guild_id: guild_id} = event,
        _ws_state,
        context
      ) do
    case Handler.invoke_configured_action(
           :GUILD_SCHEDULED_EVENT_UPDATE,
           %{discord_id: event_id},
           %{data: event},
           context
         ) do
      {:ok, _scheduled_event} ->
        :ok

      {:error, error} ->
        Logger.warning(
          "Failed to update guild scheduled event #{event_id} in guild #{guild_id}: #{inspect(error)}"
        )

        :ok
    end
  end

  @spec delete(
          consumer :: module(),
          event :: Payloads.GuildScheduledEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def delete(
        _consumer,
        %Payloads.GuildScheduledEvent{id: event_id, guild_id: guild_id},
        _ws_state,
        context
      ) do
    case Handler.invoke_configured_action(
           :GUILD_SCHEDULED_EVENT_DELETE,
           %{discord_id: event_id},
           %{},
           context
         ) do
      {:ok, _} ->
        Logger.info("Deleted guild scheduled event #{event_id} from guild #{guild_id}")
        :ok

      {:error, error} ->
        Logger.warning(
          "Failed to delete guild scheduled event #{event_id} from guild #{guild_id}: #{inspect(error)}"
        )

        :ok
    end
  end

  @spec user_add(
          consumer :: module(),
          event :: Payloads.GuildScheduledEventUserAdd.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def user_add(_consumer, event, _ws_state, context) do
    # GUILD_SCHEDULED_EVENT_USER_ADD is an informational event sent when a user
    # subscribes to a scheduled event.
    case Handler.invoke_configured_action(
           :GUILD_SCHEDULED_EVENT_USER_ADD,
           %{
             guild_scheduled_event_discord_id: event.guild_scheduled_event_id,
             user_discord_id: event.user_id
           },
           %{data: event},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @spec user_remove(
          consumer :: module(),
          event :: Payloads.GuildScheduledEventUserRemove.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def user_remove(_consumer, event, _ws_state, context) do
    # GUILD_SCHEDULED_EVENT_USER_REMOVE is an informational event sent when a user
    # unsubscribes from a scheduled event.
    case Handler.invoke_configured_action(
           :GUILD_SCHEDULED_EVENT_USER_REMOVE,
           %{
             guild_scheduled_event_discord_id: event.guild_scheduled_event_id,
             user_discord_id: event.user_id
           },
           %{},
           context
         ) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
