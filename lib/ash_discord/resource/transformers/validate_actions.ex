defmodule AshDiscord.Resource.Transformers.ValidateActions do
  @moduledoc """
  Validates that all actions referenced in Discord event mappings exist on the resource.

  This transformer reads the event map created by ExpandEntityEvents and verifies
  that each action name corresponds to a real action on the resource.

  If an action doesn't exist, raises a helpful error showing:
  - Which event mapping is invalid
  - The missing action name
  - List of available actions on the resource
  """

  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  @impl Spark.Dsl.Transformer
  def after?(AshDiscord.Resource.Transformers.ExpandEntityEvents), do: true
  def after?(_), do: false

  @impl Spark.Dsl.Transformer
  def before?(AshDiscord.Resource.Transformers.RegisterEvents), do: true
  def before?(_), do: false

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    # Get the event map from previous transformer
    event_map = Transformer.get_persisted(dsl_state, :discord_event_map, %{})

    # Get all actions defined on the resource
    available_actions =
      dsl_state
      |> Ash.Resource.Info.actions()
      |> Enum.map(& &1.name)
      |> MapSet.new()

    # Validate each action in the event map
    case validate_actions(event_map, available_actions, dsl_state) do
      :ok -> {:ok, dsl_state}
      {:error, error} -> {:error, error}
    end
  end

  defp validate_actions(event_map, available_actions, dsl_state) do
    invalid_mappings =
      event_map
      |> Enum.filter(fn {_event, action} -> action not in available_actions end)
      |> Enum.map(fn {event, action} -> {event, action} end)

    case invalid_mappings do
      [] ->
        :ok

      invalid ->
        resource = Transformer.get_persisted(dsl_state, :module)
        entity_type = Transformer.get_option(dsl_state, [:ash_discord], :discord_entity)

        error_message = format_error_message(invalid, resource, available_actions, entity_type)

        {:error,
         DslError.exception(
           module: resource,
           message: error_message,
           path: [:ash_discord]
         )}
    end
  end

  defp format_error_message(invalid_mappings, resource, available_actions, entity_type) do
    invalid_list =
      invalid_mappings
      |> Enum.map(fn {event, action} ->
        source =
          if entity_type do
            "via discord_entity :#{entity_type}"
          else
            "via events: on :#{event}, :#{action}"
          end

        "  • :#{event} → :#{action} (#{source})"
      end)
      |> Enum.join("\n")

    available_list =
      available_actions
      |> MapSet.to_list()
      |> Enum.map(&":#{&1}")
      |> Enum.join(", ")

    """
    Invalid action(s) in #{inspect(resource)}

    The following Discord event mappings reference actions that don't exist:

    #{invalid_list}

    Available actions: [#{available_list}]

    Please ensure all actions referenced in your ash_discord configuration exist on the resource.
    """
  end
end
