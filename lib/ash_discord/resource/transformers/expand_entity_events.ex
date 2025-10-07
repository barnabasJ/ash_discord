defmodule AshDiscord.Resource.Transformers.ExpandEntityEvents do
  @moduledoc """
  Expands `discord_entity` declarations to explicit event→action mappings.

  This transformer:
  1. Reads the `discord_entity` option from the `ash_discord` section
  2. Looks up default event mappings for that entity type
  3. Reads any explicit `events do` mappings
  4. Merges them (explicit mappings override entity defaults)
  5. Stores the final event map in dsl_state for later transformers

  ## Example

      # Input DSL:
      ash_discord do
        discord_entity :message
        events do
          on :MESSAGE_DELETE, :soft_delete  # Override default
        end
      end

      # After this transformer:
      # Event map: %{
      #   MESSAGE_CREATE: :from_discord,      # from entity default
      #   MESSAGE_UPDATE: :from_discord,      # from entity default
      #   MESSAGE_DELETE: :soft_delete,       # explicit override
      #   MESSAGE_DELETE_BULK: :destroy       # from entity default
      # }
  """

  use Spark.Dsl.Transformer

  alias AshDiscord.Resource.EntityEvents
  alias Spark.Dsl.Transformer

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    # Get discord_entity if specified
    entity_type = Transformer.get_option(dsl_state, [:ash_discord], :discord_entity)

    # Get explicit event mappings from events section
    explicit_events =
      dsl_state
      |> Transformer.get_entities([:ash_discord, :events])
      |> Enum.map(fn event_mapping -> {event_mapping.event, event_mapping.action} end)
      |> Map.new()

    # Build final event map
    event_map =
      case entity_type do
        nil ->
          # No entity type, only use explicit events
          explicit_events

        entity_type ->
          # Get default events for entity type and merge with explicit
          default_events =
            entity_type
            |> EntityEvents.events_for()
            |> Map.new()

          Map.merge(default_events, explicit_events)
      end

    # Store the event map in dsl_state for later transformers
    {:ok, Transformer.persist(dsl_state, :discord_event_map, event_map)}
  end
end
