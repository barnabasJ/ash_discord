defmodule AshDiscord.ResponseFormatter do
  @moduledoc """
  Behavior for formatting Ash action results into Discord responses.

  This module defines the pluggable formatter interface that allows applications
  to customize how Discord interaction responses are formatted. Applications can
  implement this behavior to provide custom formatting logic.

  ## Custom Formatters

  To create a custom formatter, implement the `AshDiscord.ResponseFormatter` behavior:

      defmodule MyApp.Discord.CustomFormatter do
        @behaviour AshDiscord.ResponseFormatter

        @impl true
        def format_success(result, context) do
          # Custom success formatting logic
          %{
            type: 4,
            data: %{
              content: "Custom success: " <> inspect(result),
              flags: 64
            }
          }
        end

        @impl true
        def format_error(error, context) do
          # Custom error formatting logic
          %{
            type: 4,
            data: %{
              content: "Custom error: " <> inspect(error),
              flags: 64
            }
          }
        end

        @impl true
        def format_validation_errors(errors, context) do
          # Custom validation error formatting
          error_messages = Enum.map_join(errors, "\n", &inspect/1)
          %{
            type: 4,
            data: %{
              content: "Validation errors:\n" <> error_messages,
              flags: 64
            }
          }
        end
      end

  ## Configuration

  Formatters can be configured per-command in the Discord DSL:

      discord do
        command :weather, WeatherResource, :get_weather do
          description "Get weather for any location"
          formatter MyApp.Discord.WeatherFormatter
        end
      end

  If no formatter is specified, the default formatter (`AshDiscord.ResponseFormatter.Default`) is used.
  """

  @doc """
  Formats a successful Ash action result into a Discord interaction response.

  ## Parameters

  * `result` - The successful result from the Ash action
  * `context` - Context map containing interaction, command, and other metadata

  ## Returns

  A Discord interaction response map with the following structure:

      %{
        type: 4, # CHANNEL_MESSAGE_WITH_SOURCE
        data: %{
          content: "Response message",
          embeds: [...], # Optional
          components: [...], # Optional
          flags: 64 # EPHEMERAL flag (optional)
        }
      }
  """
  @callback format_success(result :: any(), context :: map()) :: map()

  @doc """
  Formats an error into a Discord interaction response.

  ## Parameters

  * `error` - The error message or struct
  * `context` - Context map containing interaction, command, and other metadata

  ## Returns

  A Discord interaction response map for displaying the error to the user.
  """
  @callback format_error(error :: any(), context :: map()) :: map()

  @doc """
  Formats validation errors into a Discord interaction response.

  ## Parameters

  * `errors` - List of validation errors from Ash
  * `context` - Context map containing interaction, command, and other metadata

  ## Returns

  A Discord interaction response map for displaying validation errors to the user.
  """
  @callback format_validation_errors(errors :: list(), context :: map()) :: map()

  require Logger

  @doc """
  Main entry point for formatting responses.

  This function determines the appropriate formatter to use and delegates
  to the correct callback based on the result type.
  """
  def format_response(result, interaction, command) do
    formatter = get_formatter(command)
    context = build_context(interaction, command)

    case result do
      {:ok, success_result} ->
        formatter.format_success(success_result, context)

      {:error, %{errors: validation_errors}} when is_list(validation_errors) ->
        formatter.format_validation_errors(validation_errors, context)

      {:error, error} ->
        formatter.format_error(error, context)

      success_result ->
        formatter.format_success(success_result, context)
    end
  end

  @doc """
  Determines which formatter to use for a given command.

  Returns the configured formatter module, or the default formatter if none is specified.
  """
  def get_formatter(command) do
    command.formatter || AshDiscord.ResponseFormatter.Default
  end

  @doc """
  Builds the context map passed to formatter callbacks.
  """
  def build_context(interaction, command) do
    %{
      interaction: interaction,
      command: command,
      user_id: extract_user_id(interaction),
      guild_id: Map.get(interaction, :guild_id),
      channel_id: Map.get(interaction, :channel_id)
    }
  end

  defp extract_user_id(interaction) do
    cond do
      Map.has_key?(interaction, :user) && interaction.user ->
        interaction.user.id

      Map.has_key?(interaction, :member) && Map.has_key?(interaction.member, :user) ->
        interaction.member.user.id

      true ->
        nil
    end
  end
end
