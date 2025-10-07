defmodule AshDiscord.Consumer.Transformers.DiscoverAndValidateResources do
  @moduledoc """
  Discovers Discord event handler resources and validates no conflicts exist.

  This transformer runs during consumer compilation and:
  1. Discovers all resources with AshDiscord.Resource extension from configured domains
  2. Builds a complete event→{resource, action} mapping
  3. Detects conflicts (multiple resources handling the same event)
  4. Raises a compile-time error if conflicts are found
  5. Persists the event handler map for runtime use

  ## Conflict Detection

  If two or more resources attempt to handle the same Discord event, this transformer
  will raise a helpful error showing:
  - Which events have conflicts
  - Which resources are conflicting
  - How each resource declared the handler (entity vs explicit)

  ## Example Error

      ** (Spark.Error.DslError) Discord event conflict in MyApp.DiscordConsumer

      Multiple resources handle the same Discord event:

        • MESSAGE_CREATE
          - MyApp.Message (via discord_entity :message)
          - MyApp.ActivityLogger (via events: on :MESSAGE_CREATE, :log)

      Each event can only be handled by one resource.
  """

  use Spark.Dsl.Transformer

  alias AshDiscord.Consumer.ResourceDiscovery
  alias AshDiscord.Resource.Info, as: ResourceInfo
  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    # Get configured domains
    case Transformer.get_option(dsl_state, [:ash_discord_consumer], :domains) do
      nil ->
        {:ok, dsl_state}

      [] ->
        {:ok, dsl_state}

      domains ->
        # Discover event handlers from domains
        case ResourceDiscovery.discover_event_handlers(domains) do
          {:ok, event_map} ->
            # No conflicts, persist the event map
            dsl_state = Transformer.persist(dsl_state, :discord_event_handlers, event_map)
            {:ok, dsl_state}

          {:error, conflicts} ->
            # Conflicts found, raise error
            consumer = Transformer.get_persisted(dsl_state, :module)
            {:error, build_conflict_error(consumer, conflicts, domains)}
        end
    end
  end

  defp build_conflict_error(consumer, conflicts, domains) do
    conflict_details =
      conflicts
      |> Enum.map(fn {event, handlers} ->
        handler_lines =
          handlers
          |> Enum.map(fn {resource, action} ->
            source = get_handler_source(resource, event, action)
            "    - #{inspect(resource)} (#{source})"
          end)
          |> Enum.join("\n")

        """
          • #{event}
        #{handler_lines}
        """
      end)
      |> Enum.join("\n")

    message = """
    Discord event conflict in #{inspect(consumer)}

    Multiple resources handle the same Discord event:

    #{conflict_details}

    Each event can only be handled by one resource.
    Please remove duplicate handlers or combine logic into a single resource.

    Configured domains: #{inspect(domains)}
    """

    DslError.exception(
      module: consumer,
      message: message,
      path: [:ash_discord_consumer, :domains]
    )
  end

  defp get_handler_source(resource, event, action) do
    case ResourceInfo.discord_entity(resource) do
      {:ok, entity_type} ->
        # Check if this event comes from the entity type defaults
        entity_events =
          entity_type
          |> AshDiscord.Resource.EntityEvents.events_for()
          |> Map.new()

        if Map.get(entity_events, event) == action do
          "via discord_entity :#{entity_type}"
        else
          "via events: on :#{event}, :#{action}"
        end

      :error ->
        "via events: on :#{event}, :#{action}"
    end
  end
end
