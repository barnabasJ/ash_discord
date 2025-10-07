defmodule AshDiscord.Consumer.ResourceDiscovery do
  @moduledoc """
  Discovers Discord event handlers from resources in configured domains.

  This module scans Ash domains for resources with the AshDiscord.Resource extension
  and builds a complete event→resource+action mapping for the consumer to use at runtime.

  ## Conflict Detection

  If multiple resources attempt to handle the same Discord event, this module
  will return conflict information for the consumer transformer to raise an error.

  ## Examples

      iex> domains = [MyApp.Discord]
      iex> AshDiscord.Consumer.ResourceDiscovery.discover_event_handlers(domains)
      {:ok, %{
        MESSAGE_CREATE: {MyApp.Message, :from_discord},
        GUILD_CREATE: {MyApp.Guild, :from_discord},
        USER_UPDATE: {MyApp.User, :from_discord}
      }}

      # With conflicts:
      iex> AshDiscord.Consumer.ResourceDiscovery.discover_event_handlers(domains)
      {:error, %{
        MESSAGE_CREATE: [
          {MyApp.Message, :from_discord},
          {MyApp.ActivityLogger, :log_message}
        ]
      }}
  """

  alias AshDiscord.Resource.Info, as: ResourceInfo

  @type event :: atom()
  @type resource :: module()
  @type action :: atom()
  @type handler :: {resource(), action()}
  @type event_map :: %{event() => handler()}
  @type conflicts :: %{event() => [handler()]}

  @doc """
  Discovers all Discord event handlers from the given domains.

  Returns `{:ok, event_map}` if no conflicts are found, or
  `{:error, conflicts}` if multiple resources handle the same event.

  ## Examples

      iex> discover_event_handlers([MyApp.Discord])
      {:ok, %{MESSAGE_CREATE: {MyApp.Message, :from_discord}}}

      # With conflicts:
      iex> discover_event_handlers([MyApp.Discord])
      {:error, %{
        MESSAGE_CREATE: [{MyApp.Message, :from_discord}, {MyApp.Logger, :log}]
      }}
  """
  @spec discover_event_handlers([module()]) :: {:ok, event_map()} | {:error, conflicts()}
  def discover_event_handlers(domains) do
    # Collect all event handlers from all resources
    all_handlers =
      domains
      |> collect_resources()
      |> Enum.filter(&ResourceInfo.ash_discord_resource?/1)
      |> Enum.flat_map(&extract_event_handlers/1)

    # Group by event to detect conflicts
    grouped_by_event = Enum.group_by(all_handlers, fn {event, _resource, _action} -> event end)

    # Check for conflicts
    conflicts =
      grouped_by_event
      |> Enum.filter(fn {_event, handlers} -> length(handlers) > 1 end)
      |> Enum.into(%{}, fn {event, handlers} ->
        # Extract just resource and action for conflict reporting
        conflicting_handlers =
          Enum.map(handlers, fn {_event, resource, action} -> {resource, action} end)

        {event, conflicting_handlers}
      end)

    case conflicts do
      empty when map_size(empty) == 0 ->
        # No conflicts, build clean event map
        event_map =
          grouped_by_event
          |> Enum.into(%{}, fn {event, [{_event, resource, action}]} ->
            {event, {resource, action}}
          end)

        {:ok, event_map}

      conflicts ->
        {:error, conflicts}
    end
  end

  @doc """
  Collects all resources from the given domains.

  ## Examples

      iex> collect_resources([MyApp.Discord])
      [MyApp.Message, MyApp.Guild, MyApp.Channel]
  """
  @spec collect_resources([module()]) :: [module()]
  def collect_resources(domains) do
    domains
    |> Enum.flat_map(fn domain ->
      try do
        Ash.Domain.Info.resources(domain)
      rescue
        # Handle case where domain doesn't exist or isn't compiled yet
        _ -> []
      end
    end)
    |> Enum.uniq()
  end

  @doc """
  Extracts event handlers from a resource with AshDiscord.Resource extension.

  Returns a list of `{event, resource, action}` tuples.

  ## Examples

      iex> extract_event_handlers(MyApp.Message)
      [
        {:MESSAGE_CREATE, MyApp.Message, :from_discord},
        {:MESSAGE_UPDATE, MyApp.Message, :from_discord},
        {:MESSAGE_DELETE, MyApp.Message, :destroy}
      ]
  """
  @spec extract_event_handlers(module()) :: [{event(), resource(), action()}]
  def extract_event_handlers(resource) do
    case ResourceInfo.discord_events(resource) do
      {:ok, event_map} ->
        Enum.map(event_map, fn {event, action} -> {event, resource, action} end)

      :error ->
        []
    end
  end
end
