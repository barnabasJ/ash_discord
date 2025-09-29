defmodule AshDiscord.Errors do
  @moduledoc """
  Enhanced error handling and reporting for AshDiscord library.

  Provides production-ready error messages with clear guidance for developers,
  structured error reporting, and context-aware error formatting.
  """

  defmodule ConfigurationError do
    @moduledoc """
    Raised when there's a configuration issue that prevents proper operation.

    Includes detailed guidance on how to fix the issue and examples of correct configuration.
    """
    defexception [:message, :context, :suggestions, :examples]

    @type t :: %__MODULE__{
            message: String.t(),
            context: map(),
            suggestions: [String.t()],
            examples: [String.t()]
          }

    def exception(opts) when is_list(opts) do
      message = Keyword.fetch!(opts, :message)
      context = Keyword.get(opts, :context, %{})
      suggestions = Keyword.get(opts, :suggestions, [])
      examples = Keyword.get(opts, :examples, [])

      %__MODULE__{
        message: message,
        context: context,
        suggestions: suggestions,
        examples: examples
      }
    end

    def message(%__MODULE__{} = error) do
      formatted_message = """
      ❌ AshDiscord Configuration Error: #{error.message}

      #{format_context(error.context)}#{format_suggestions(error.suggestions)}#{format_examples(error.examples)}
      """

      String.trim(formatted_message)
    end

    defp format_context(context) when map_size(context) == 0, do: ""

    defp format_context(context) do
      context_info =
        Enum.map_join(context, "\n", fn {key, value} -> "  #{key}: #{inspect(value)}" end)

      """

      📍 Context:
      #{context_info}

      """
    end

    defp format_suggestions([]), do: ""

    defp format_suggestions(suggestions) do
      formatted_suggestions =
        suggestions
        |> Enum.with_index(1)
        |> Enum.map_join("\n", fn {suggestion, index} -> "  #{index}. #{suggestion}" end)

      """
      💡 Suggested Fixes:
      #{formatted_suggestions}

      """
    end

    defp format_examples([]), do: ""

    defp format_examples(examples) do
      formatted_examples =
        examples
        |> Enum.with_index(1)
        |> Enum.map_join("\n", fn {example, index} -> "  #{index}. #{example}" end)

      """
      📋 Examples:
      #{formatted_examples}
      """
    end
  end

  defmodule InteractionError do
    @moduledoc """
    Errors related to Discord interaction processing.

    Includes context about the interaction and suggested recovery actions.
    """
    defexception [:message, :interaction_id, :command, :reason, :recovery_actions]

    @type t :: %__MODULE__{
            message: String.t(),
            interaction_id: String.t() | nil,
            command: String.t() | atom() | nil,
            reason: any(),
            recovery_actions: [String.t()]
          }

    def exception(opts) when is_list(opts) do
      %__MODULE__{
        message: Keyword.fetch!(opts, :message),
        interaction_id: Keyword.get(opts, :interaction_id),
        command: Keyword.get(opts, :command),
        reason: Keyword.get(opts, :reason),
        recovery_actions: Keyword.get(opts, :recovery_actions, [])
      }
    end

    def message(%__MODULE__{} = error) do
      base_message = "Discord Interaction Error: #{error.message}"

      context_parts = [
        if(error.interaction_id, do: "Interaction ID: #{error.interaction_id}"),
        if(error.command, do: "Command: #{error.command}"),
        if(error.reason, do: "Reason: #{inspect(error.reason)}")
      ]

      context = context_parts |> Enum.filter(& &1) |> Enum.join(" | ")

      recovery_section =
        if not Enum.empty?(error.recovery_actions) do
          actions = Enum.join(error.recovery_actions, "; ")
          "\nRecovery: #{actions}"
        else
          ""
        end

      "#{base_message} (#{context})#{recovery_section}"
    end
  end

  @doc """
  Creates a configuration error for invalid command definitions.
  """
  def invalid_command_error(command_name, module, issues) do
    ConfigurationError.exception(
      message: "Invalid command definition '#{command_name}' in #{inspect(module)}",
      context: %{
        command: command_name,
        module: module,
        issues: issues
      },
      suggestions: command_suggestions(issues),
      examples: command_examples(issues)
    )
  end

  @doc """
  Creates a configuration error for missing or invalid resources.
  """
  def invalid_resource_error(resource, action, module) do
    ConfigurationError.exception(
      message: "Resource #{inspect(resource)} or action #{action} not found",
      context: %{
        resource: resource,
        action: action,
        module: module
      },
      suggestions: [
        "Ensure the resource module exists and is properly defined",
        "Check that the action is defined on the resource",
        "Verify the resource is included in the domain's resource list",
        "Make sure the resource modules are compiled before the domain"
      ],
      examples: [
        "defmodule MyApp.Chat.Conversation do; use Ash.Resource; end",
        "resources do; resource MyApp.Chat.Conversation; end",
        "actions do; create :create_conversation; end"
      ]
    )
  end

  @doc """
  Creates an interaction error with recovery guidance.
  """
  def interaction_error(message, opts \\ []) do
    InteractionError.exception(Keyword.put(opts, :message, message))
  end

  @doc """
  Formats Ash errors with user-friendly messages and developer context.
  """
  def format_ash_error(error, context \\ %{}) do
    case error do
      %Ash.Error.Invalid{} = invalid_error ->
        format_ash_invalid_error(invalid_error, context)

      %Ash.Error.Forbidden{} ->
        %{
          user_message: "You don't have permission to perform this action",
          developer_message: "Authorization failed for the requested action",
          error_type: :forbidden,
          context: context
        }

      %{__struct__: struct_name} ->
        if struct_name |> to_string() |> String.contains?("NotFound") do
          %{
            user_message: "The requested resource was not found",
            developer_message: "Resource lookup failed",
            error_type: :not_found,
            context: context
          }
        else
          %{
            user_message: "Command failed to execute",
            developer_message: inspect(error),
            error_type: :unknown,
            context: context
          }
        end

      _other ->
        %{
          user_message: "An unexpected error occurred",
          developer_message: inspect(error),
          error_type: :unknown,
          context: context
        }
    end
  end

  defp format_ash_invalid_error(error, context) do
    field_errors =
      error
      |> Ash.Error.to_error_class()
      |> case do
        %Ash.Error.Invalid{errors: errors} ->
          Enum.map(errors, &format_field_error/1)

        _ ->
          ["Invalid input provided"]
      end

    user_message =
      if length(field_errors) == 1 do
        "#{List.first(field_errors)}"
      else
        "Multiple validation errors: " <> Enum.join(field_errors, "; ")
      end

    %{
      user_message: user_message,
      developer_message: Exception.message(error),
      error_type: :validation,
      field_errors: field_errors,
      context: context
    }
  end

  defp format_field_error(error) do
    case error do
      %Ash.Error.Changes.InvalidAttribute{field: field, message: message} ->
        "#{field}: #{message}"

      %Ash.Error.Changes.InvalidArgument{field: field, message: message} ->
        "#{field}: #{message}"

      %Ash.Error.Changes.Required{field: field} ->
        "#{field} is required"

      error ->
        Exception.message(error)
    end
  end

  defp command_suggestions(issues) do
    base_suggestions = [
      "Check command name uses only lowercase letters, numbers, underscores, and hyphens",
      "Ensure command description is 1-100 characters long",
      "Verify all command options have valid names and descriptions",
      "Make sure referenced resource and action exist"
    ]

    # Add specific suggestions based on issues
    specific_suggestions =
      Enum.flat_map(issues, fn issue ->
        case issue do
          :invalid_name -> ["Command names must match pattern: ^[a-z0-9_-]+$"]
          :name_too_long -> ["Command names must be 32 characters or less"]
          :missing_description -> ["Add description to chat_input commands"]
          :description_too_long -> ["Descriptions must be 100 characters or less"]
          :too_many_options -> ["Commands can have maximum 25 options"]
          :invalid_option_name -> ["Option names must match pattern: ^[a-z0-9_-]+$"]
          _ -> []
        end
      end)

    base_suggestions ++ specific_suggestions
  end

  defp command_examples(issues) do
    if :missing_description in issues do
      [
        """
        command :chat, MyApp.Chat.Conversation, :create do
          description "Start an AI conversation"
          option :message, :string, required: true, description: "Your message"
        end
        """
      ]
    else
      [
        "command :valid_name, MyApp.Resource, :action do; description \"Valid command\"; end",
        "option :param_name, :string, description: \"Parameter description\""
      ]
    end
  end
end
