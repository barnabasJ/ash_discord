defmodule AshDiscord.Transformers.AutoDetectOptions do
  @moduledoc """
  Automatically detects Discord command options from Ash action inputs.

  This transformer inspects the action's arguments and accepted attributes
  to automatically generate Discord slash command options, removing the need
  to manually define them in the DSL.
  """

  use Spark.Dsl.Transformer

  alias Ash.Resource.Info
  alias Ash.Type.Boolean
  alias Ash.Type.Decimal
  alias Ash.Type.UtcDatetime
  alias Ash.Type.UtcDatetimeUsec
  alias Ash.Type.UUID
  alias Spark.Dsl.Extension
  alias Spark.Dsl.Transformer
  alias AshDiscord.Option
  alias AshDiscord.Transformers.EnhanceCommands
  alias AshDiscord.Transformers.ValidateCommands

  require Logger

  @impl true
  def transform(dsl_state) do
    discord_commands = Extension.get_entities(dsl_state, [:discord])

    # Apply auto-detection to each command and replace it in the DSL state
    dsl_state =
      Enum.reduce(discord_commands, dsl_state, fn command, acc ->
        enhanced_command = enhance_command_with_auto_options(command, acc)

        Transformer.replace_entity(acc, [:discord], enhanced_command, fn entity ->
          entity.name == command.name
        end)
      end)

    {:ok, dsl_state}
  end

  defp enhance_command_with_auto_options(command, _dsl_state) do
    # TODO: we should check if the action has any required inputs and
    # show an error if the type of command doesn't support options
    # Context menu commands (:user and :message types) cannot have options
    if command.type in [:user, :message] do
      Logger.debug("Skipping option auto-detection for context menu command: #{command.name}")
      %{command | options: []}
    else
      # Auto-detect options from the action for slash commands
      auto_options = detect_options_from_action(command.resource, command.action)
      merge_command_options(command, auto_options)
    end
  end

  defp merge_command_options(command, auto_options) do
    if command.options == [] do
      # Use only auto-detected options
      %{command | options: auto_options}
    else
      # Manual options override all auto-detection
      # Don't add any auto-detected options when manual ones are provided
      command
    end
  end

  defp detect_options_from_action(resource, action_name) do
    case Info.action(resource, action_name) do
      nil ->
        Logger.warning("Action #{action_name} not found on resource #{inspect(resource)}")
        []

      action ->
        # Get options from action arguments
        argument_options = Enum.map(action.arguments, &argument_to_option/1)

        # Get options from accepted attributes (only for create/update actions)
        attribute_options = get_attribute_options(action, resource)

        # Combine and deduplicate by name
        (argument_options ++ attribute_options)
        |> Enum.uniq_by(& &1.name)
    end
  end

  defp get_attribute_options(action, resource) do
    if Map.has_key?(action, :accept) and action.accept != nil do
      action.accept
      |> Enum.map(&get_attribute_option(resource, &1))
      |> Enum.reject(&is_nil/1)
    else
      []
    end
  end

  defp get_attribute_option(resource, attr_name) do
    case Info.attribute(resource, attr_name) do
      nil -> nil
      attr -> attribute_to_option(attr)
    end
  end

  defp argument_to_option(argument) do
    %Option{
      name: argument.name,
      type: ash_type_to_discord_type(argument.type),
      description: argument.description || "Auto-detected option",
      required: not argument.allow_nil?,
      choices: detect_choices_from_constraints(argument.type, argument.constraints)
    }
  end

  defp attribute_to_option(attribute) do
    %Option{
      name: attribute.name,
      type: ash_type_to_discord_type(attribute.type),
      description: attribute.description || "Auto-detected option",
      required: not attribute.allow_nil?,
      choices: detect_choices_from_constraints(attribute.type, attribute.constraints)
    }
  end

  defp ash_type_to_discord_type(type) do
    type
    |> normalize_ash_type()
    |> convert_to_discord_type()
  end

  defp normalize_ash_type(type) do
    case type do
      module when is_atom(module) ->
        if function_exported?(module, :storage_type, 0) do
          module.storage_type()
        else
          module
        end

      other ->
        other
    end
  end

  defp convert_to_discord_type(base_type) do
    case base_type do
      type when type in [:string, Ash.Type.String] ->
        :string

      type when type in [:integer, Ash.Type.Integer] ->
        :integer

      type when type in [:boolean, Boolean] ->
        :boolean

      type when type in [:float, Ash.Type.Float, :decimal, Decimal] ->
        :number

      type when type in [UUID, :uuid] ->
        :string

      type
      when type in [
             :utc_datetime,
             :utc_datetime_usec,
             UtcDatetime,
             UtcDatetimeUsec
           ] ->
        :string

      _ ->
        :string
    end
  end

  defp detect_choices_from_constraints(_type, constraints) do
    # Check if constraints include an enum/one_of constraint
    cond do
      Keyword.has_key?(constraints, :one_of) ->
        constraints[:one_of]
        |> Enum.map(fn value ->
          %{
            name: to_string(value),
            value: to_string(value)
          }
        end)

      Keyword.has_key?(constraints, :values) ->
        constraints[:values]
        |> Enum.map(fn value ->
          %{
            name: to_string(value),
            value: to_string(value)
          }
        end)

      true ->
        []
    end
  end

  @impl true
  def after?(ValidateCommands), do: true
  def after?(_), do: false

  @impl true
  def before?(EnhanceCommands), do: true
  def before?(_), do: false
end
