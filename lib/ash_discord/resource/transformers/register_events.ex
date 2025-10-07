defmodule AshDiscord.Resource.Transformers.RegisterEvents do
  @moduledoc """
  Registers Discord event mappings for consumer discovery.

  This transformer persists the final event→action map in the dsl_state
  so it can be discovered by the consumer at compile time.

  The event map is stored with the key `:ash_discord_events` and can be
  retrieved using `Spark.Dsl.Extension.get_persisted/2`.
  """

  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    # Get the validated event map from previous transformers
    event_map = Transformer.get_persisted(dsl_state, :discord_event_map, %{})

    # Persist it with a well-known key for consumer discovery
    dsl_state = Transformer.persist(dsl_state, :ash_discord_events, event_map)

    # Also persist the entity type if specified
    entity_type = Transformer.get_option(dsl_state, [:ash_discord], :discord_entity)

    dsl_state =
      if entity_type do
        Transformer.persist(dsl_state, :ash_discord_entity_type, entity_type)
      else
        dsl_state
      end

    {:ok, dsl_state}
  end
end
