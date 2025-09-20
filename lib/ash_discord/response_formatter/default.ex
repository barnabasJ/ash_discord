defmodule AshDiscord.ResponseFormatter.Default do
  @moduledoc """
  Default implementation of the AshDiscord.ResponseFormatter behavior.

  This formatter provides sensible defaults for formatting Ash action results
  into Discord interaction responses. It handles common result types and provides
  basic error formatting.

  Applications can use this as a reference implementation when creating custom
  formatters or extend it for specific use cases.
  """

  @behaviour AshDiscord.ResponseFormatter

  require Logger

  @impl true
  def format_success(result, context) do
    content = format_success_content(result, context)

    %{
      type: 4,
      data: %{
        content: content,
        flags: 64
      }
    }
  end

  @impl true
  def format_error(error, _context) do
    content = format_error_content(error)

    %{
      type: 4,
      data: %{
        content: "Error: #{content}",
        flags: 64
      }
    }
  end

  @impl true
  def format_validation_errors(errors, _context) do
    content = format_validation_errors_content(errors)

    %{
      type: 4,
      data: %{
        content: "Validation errors:\n#{content}",
        flags: 64
      }
    }
  end

  # Private functions for formatting content

  defp format_success_content(result, context) do
    case result do
      %{__struct__: _} ->
        "#{context.command.action} completed successfully!"

      result when is_list(result) ->
        "Found #{length(result)} items"

      result when is_binary(result) ->
        result

      # Handle message move results
      %{total_found: _total_found, related_messages: _messages, search_parameters: _params} =
          result ->
        format_message_move_result(result)

      result when is_map(result) ->
        "#{context.command.action} completed successfully!"

      _ ->
        "Command completed successfully!"
    end
  end

  defp format_error_content(error) when is_binary(error), do: error

  defp format_error_content(error) do
    case error do
      %Ash.Error.Invalid{} ->
        "Invalid input provided"

      %Ash.Error.Forbidden{} ->
        "You don't have permission to perform this action"

      %{message: message} when is_binary(message) ->
        message

      _ ->
        "Command failed to execute"
    end
  end

  defp format_validation_errors_content(errors) when is_list(errors) do
    errors
    |> Enum.map(&format_single_validation_error/1)
    |> Enum.join("\n")
  end

  defp format_validation_errors_content(_), do: "Invalid input provided"

  defp format_single_validation_error(%{field: field, message: message})
       when is_binary(message) do
    "• #{field}: #{message}"
  end

  defp format_single_validation_error(%{message: message}) when is_binary(message) do
    "• #{message}"
  end

  defp format_single_validation_error(error) when is_binary(error) do
    "• #{error}"
  end

  defp format_single_validation_error(error) do
    "• #{inspect(error)}"
  end

  # Message move result formatting (preserved from original implementation)
  defp format_message_move_result(%{
         total_found: total_found,
         related_messages: messages,
         search_parameters: params
       }) do
    # Create a summary of the messages found
    messages_to_show = Enum.take(messages, 3)

    message_summaries =
      messages_to_show
      |> Enum.map_join("\n", fn %{message: msg, content_preview: preview} ->
        author_name = if msg.author, do: msg.author.discord_username, else: "Unknown"

        "• **#{author_name}**: #{preview}#{if String.length(msg.content || "") > 100, do: "...", else: ""}"
      end)

    shown_count = length(messages_to_show)
    remaining_count = total_found - shown_count

    search_type =
      if Map.get(params, :single_message), do: "single message", else: "conversation thread"

    content = """
    **Found #{total_found} message#{if total_found == 1, do: "", else: "s"} in #{search_type}**

    #{message_summaries}#{if remaining_count > 0, do: "\n... and #{remaining_count} more", else: ""}

    _Note: This is a preview of messages that would be moved. Full move functionality requires destination channel selection._
    """

    String.trim(content)
  end
end
