defmodule AshDiscord.InteractionRouter do
  @moduledoc """
  Routes Discord interactions to appropriate Ash actions.

  This module handles the core logic of converting Discord interaction data
  into Ash action inputs and executing the actions with proper actor context.
  """

  require Ash.Query
  require Logger
  alias AshDiscord.Logger, as: AshLogger

  @doc """
  Routes a Discord interaction to the corresponding Ash action.
  """
  def route_interaction(interaction, command, opts \\ []) do
    timer = AshLogger.start_timer("route_interaction")

    if is_nil(command) do
      AshLogger.log_interaction(:error, "Cannot route interaction: command is nil", interaction)
      send_error_response(interaction, "Unknown command")
      {:error, :unknown_command}
    else
      AshLogger.log_interaction(
        :debug,
        "Routing interaction for command: #{command.name}",
        interaction
      )

      consumer_module = Keyword.get(opts, :consumer)

      result =
        with {:ok, actor} <- resolve_actor_from_discord(interaction, consumer_module),
             {:ok, input} <- transform_input(interaction, command),
             {:ok, action_result} <- execute_action(command, input, actor, interaction),
             {:ok, response} <- format_response(action_result, interaction, command) do
          Nostrum.Api.Interaction.create_response(interaction.id, interaction.token, response)
        else
          {:error, reason} ->
            AshLogger.log_interaction(:error, "Failed to route interaction", interaction, %{
              error: reason,
              command: command.name
            })

            send_error_response(interaction, reason)
        end

      execution_time =
        AshLogger.end_timer(timer, 100, %{command: command.name, interaction_id: interaction.id})

      AshLogger.log_command_execution(command, interaction, result, execution_time)

      result
    end
  end

  defp resolve_actor_from_discord(interaction, consumer_module) do
    discord_user = extract_discord_user(interaction)

    if discord_user do
      case AshDiscord.Consumer.Info.ash_discord_consumer_user_resource(consumer_module) do
        {:ok, user_resource} ->
          case user_resource
               |> Ash.Changeset.for_create(:from_discord, %{
                 discord_id: discord_user.id,
                 discord_struct: discord_user
               })
               |> Ash.Changeset.set_context(%{
                 shared: %{private: %{ash_discord?: true}},
                 private: %{ash_discord?: true}
               })
               |> Ash.create() do
            {:ok, user} ->
              AshLogger.log_interaction(
                :debug,
                "Resolved user actor via from_discord",
                interaction,
                %{
                  actor_id: user.id,
                  discord_user_id: discord_user.id
                }
              )

              {:ok, user}

            {:error, reason} ->
              AshLogger.log_interaction(
                :error,
                "Failed to create/find user via from_discord",
                interaction,
                %{
                  error: reason,
                  discord_user_id: discord_user.id
                }
              )

              {:error, :user_creation_failed}
          end

        # no user resource configured, continue with raw discord user
        :error ->
          {:ok, discord_user}
      end
    else
      Logger.debug("No discord user found, cannot proceed without user")
      {:error, "Authentication required - no Discord user found"}
    end
  end

  defp extract_discord_user(interaction) do
    cond do
      Map.has_key?(interaction, :user) && interaction.user ->
        interaction.user

      Map.has_key?(interaction, :member) && Map.has_key?(interaction.member, :user) ->
        interaction.member.user

      true ->
        nil
    end
  end

  def transform_input(interaction, command) do
    action_input = build_action_input(command.resource, command.action, interaction)

    action = Ash.Resource.Info.action(command.resource, command.action)
    filtered_input = filter_input_for_action(action, action_input)

    {:ok, filtered_input}
  end

  defp execute_action(command, input, actor, interaction) do
    action = Ash.Resource.Info.action(command.resource, command.action)

    if action do
      execute_action_with_info(action, command.resource, input, actor, interaction)
    else
      Logger.error("Action #{command.action} not found on resource #{command.resource}")
      {:error, "Unknown action"}
    end
  end

  defp execute_action_with_info(action, resource, input, actor, interaction) do
    context = %{
      nostrum_data: interaction
    }

    AshLogger.log_interaction(:debug, "Executing Ash action", interaction, %{
      resource: resource,
      action: action.name,
      action_type: action.type,
      input_keys: Map.keys(input),
      has_actor: not is_nil(actor)
    })

    action_timer = AshLogger.start_timer("ash_action_#{action.type}")

    result =
      case action.type do
        :create ->
          changeset =
            Ash.Changeset.for_create(resource, action.name, input, actor: actor, context: context)

          Ash.create(changeset)

        :read ->
          query = Ash.Query.for_read(resource, action.name, input, actor: actor, context: context)
          Ash.read(query)

        :update ->
          {:error, "Update actions not yet supported"}

        :destroy ->
          {:error, "Destroy actions not yet supported"}

        :action ->
          # Handle generic actions that don't fit into CRUD operations
          resource
          |> Ash.ActionInput.for_action(action.name, input, actor: actor, context: context)
          |> Ash.run_action()

        _ ->
          {:error, "Unsupported action type: #{action.type}"}
      end

    execution_time =
      AshLogger.end_timer(action_timer, 50, %{
        resource: resource,
        action: action.name,
        interaction_id: interaction.id
      })

    case result do
      {:ok, ash_result} ->
        AshLogger.log_ash_action(:debug, action.type, resource, action.name, result, %{
          execution_time_ms: execution_time,
          interaction_id: interaction.id
        })

        {:ok, ash_result}

      {:error, error} ->
        formatted_error =
          AshDiscord.Errors.format_ash_error(error, %{
            resource: resource,
            action: action.name,
            interaction_id: interaction.id,
            execution_time_ms: execution_time
          })

        AshLogger.log_ash_action(:error, action.type, resource, action.name, result, %{
          execution_time_ms: execution_time,
          interaction_id: interaction.id,
          formatted_error: formatted_error
        })

        {:error, formatted_error.user_message}
    end
  end

  defp build_action_input(resource, action_name, interaction) do
    action = Ash.Resource.Info.action(resource, action_name)

    if action do
      build_input_from_action(action, interaction)
    else
      build_input_from_options(interaction)
    end
  end

  defp build_input_from_action(action, interaction) do
    discord_options = extract_discord_options(interaction)

    %{}
    |> add_arguments_to_input(action.arguments, discord_options)
    |> add_accepts_to_input(action, discord_options)
    |> add_accepted_attributes_to_input(action, discord_options)

    # Context menu data is now handled by the action itself via context
  end

  defp extract_discord_options(interaction) do
    options = interaction.data.options || []

    Map.new(options, fn option ->
      {String.to_atom(option.name), option.value}
    end)
  end

  defp add_arguments_to_input(action_input, arguments, discord_options) do
    if arguments do
      Enum.reduce(arguments, action_input, fn arg, acc ->
        add_option_to_input(acc, arg.name, discord_options)
      end)
    else
      action_input
    end
  end

  defp add_accepts_to_input(action_input, action, discord_options) do
    # Only add accepts for create/update actions that have an accepts field
    if action.type in [:create, :update] and Map.has_key?(action, :accepts) and action.accepts do
      Enum.reduce(action.accepts, action_input, fn accept_field, acc ->
        add_option_to_input(acc, accept_field, discord_options)
      end)
    else
      action_input
    end
  end

  defp add_accepted_attributes_to_input(action_input, action, discord_options) do
    # Only create/update actions have an accept field
    if action.type in [:create, :update] and Map.has_key?(action, :accept) and
         action.accept != nil do
      Enum.reduce(action.accept, action_input, fn attr_name, acc ->
        add_option_to_input(acc, attr_name, discord_options)
      end)
    else
      action_input
    end
  end

  defp add_option_to_input(input, key, discord_options) do
    case Map.get(discord_options, key) do
      nil -> input
      value -> Map.put(input, key, value)
    end
  end

  defp build_input_from_options(interaction) do
    options = interaction.data.options || []

    Map.new(options, fn option ->
      {String.to_existing_atom(option.name), option.value}
    end)
  end

  defp format_response(result, interaction, command) do
    response = AshDiscord.ResponseFormatter.format_response(result, interaction, command)
    {:ok, response}
  end

  def format_ash_error(error) do
    case error do
      %Ash.Error.Invalid{} ->
        "Invalid input provided"

      %Ash.Error.Forbidden{} ->
        "You don't have permission to perform this action"

      _ ->
        "Command failed to execute"
    end
  end

  # defp default_success_response(_result) do
  #   %{
  #     type: 4,
  #     data: %{
  #       content: "Command executed successfully!",
  #       flags: 64
  #     }
  #   }
  # end

  defp send_error_response(interaction, reason) when is_binary(reason) do
    response = %{
      type: 4,
      data: %{
        content: "Error: #{reason}",
        flags: 64
      }
    }

    Nostrum.Api.Interaction.create_response(interaction.id, interaction.token, response)
  end

  defp send_error_response(interaction, _reason) do
    response = %{
      type: 4,
      data: %{
        content: "An error occurred while processing your command.",
        flags: 64
      }
    }

    Nostrum.Api.Interaction.create_response(interaction.id, interaction.token, response)
  end

  defp filter_input_for_action(action, input) do
    if action do
      accepted_inputs = get_accepted_inputs(action)
      argument_names = get_argument_names(action)
      allowed_keys = accepted_inputs ++ argument_names

      Map.take(input, allowed_keys)
    else
      input
    end
  end

  defp get_accepted_inputs(action) do
    # Only create/update actions have an accept field
    if action.type in [:create, :update] and Map.has_key?(action, :accept) do
      case action.accept do
        nil -> []
        list when is_list(list) -> list
        _ -> []
      end
    else
      []
    end
  end

  defp get_argument_names(action) do
    action.arguments
    |> Enum.map(& &1.name)
  end

  @doc """
  Parses Discord interaction options into a map with atom keys.
  """
  def parse_options(options) when is_list(options) do
    Map.new(options, fn option ->
      {String.to_atom(option.name), option.value}
    end)
  end

  def parse_options(_), do: %{}
end
