defmodule AshDiscord.Consumer.Handler.Guild.ScheduledEvent do
  @moduledoc """
  Handler for Discord Guild Scheduled Event gateway events.

  Handles CREATE, UPDATE, DELETE, USER_ADD, and USER_REMOVE events for guild scheduled events.
  """

  require Logger
  require Ash.Query

  alias AshDiscord.Consumer.Payloads

  @spec create(
          consumer :: module(),
          event :: Payloads.GuildScheduledEvent.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def create(
        _consumer,
        %Payloads.GuildScheduledEvent{} = event,
        _ws_state,
        context
      ) do
    case context.resource do
      nil ->
        :ok

      resource ->
        case resource
             |> Ash.Changeset.for_create(
               :from_discord,
               %{data: event},
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               }
             )
             |> Ash.create() do
          {:ok, _scheduled_event} ->
            :ok

          {:error, error} ->
            Logger.warning(
              "Failed to create guild scheduled event #{event.id} in guild #{event.guild_id}: #{inspect(error)}"
            )

            :ok
        end
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
        %Payloads.GuildScheduledEvent{} = event,
        _ws_state,
        context
      ) do
    case context.resource do
      nil ->
        :ok

      resource ->
        case resource
             |> Ash.Changeset.for_create(
               :from_discord,
               %{data: event},
               context: %{
                 private: %{ash_discord?: true},
                 shared: %{private: %{ash_discord?: true}}
               }
             )
             |> Ash.create() do
          {:ok, _scheduled_event} ->
            :ok

          {:error, error} ->
            Logger.warning(
              "Failed to update guild scheduled event #{event.id} in guild #{event.guild_id}: #{inspect(error)}"
            )

            :ok
        end
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
    case context.resource do
      nil ->
        :ok

      resource ->
        query =
          resource
          |> Ash.Query.filter(discord_id == ^event_id)
          |> Ash.Query.set_context(%{
            private: %{ash_discord?: true},
            shared: %{private: %{ash_discord?: true}}
          })

        case Ash.bulk_destroy(query, :destroy, %{},
               return_errors?: true,
               return_records?: false
             ) do
          %Ash.BulkResult{status: :success} ->
            Logger.info("Deleted guild scheduled event #{event_id} from guild #{guild_id}")
            :ok

          %Ash.BulkResult{status: :error, errors: errors} ->
            Logger.warning(
              "Failed to delete guild scheduled event #{event_id} from guild #{guild_id}: #{inspect(errors)}"
            )

            :ok

          {:error, error} ->
            Logger.warning(
              "Failed to delete guild scheduled event #{event_id} from guild #{guild_id}: #{inspect(error)}"
            )

            :ok
        end
    end
  end

  @spec user_add(
          consumer :: module(),
          event :: Payloads.GuildScheduledEventUserAdd.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def user_add(_consumer, _event, _ws_state, _context) do
    # GUILD_SCHEDULED_EVENT_USER_ADD is an informational event sent when a user
    # subscribes to a scheduled event.
    #
    # This handler exists to acknowledge the event and allow users to attach
    # their own side effects if needed, but by default we just return :ok.
    :ok
  end

  @spec user_remove(
          consumer :: module(),
          event :: Payloads.GuildScheduledEventUserRemove.t(),
          ws_state :: Nostrum.Struct.WSState.t(),
          context :: AshDiscord.Context.t()
        ) :: :ok | {:error, term()}
  def user_remove(_consumer, _event, _ws_state, _context) do
    # GUILD_SCHEDULED_EVENT_USER_REMOVE is an informational event sent when a user
    # unsubscribes from a scheduled event.
    #
    # This handler exists to acknowledge the event and allow users to attach
    # their own side effects if needed, but by default we just return :ok.
    :ok
  end
end
