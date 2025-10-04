defmodule AshDiscord.Logger do
  @moduledoc """
  Structured logging for AshDiscord operations with contextual information.

  Provides production-ready logging with:
  - Structured metadata for effective debugging
  - Performance metrics for slow operations
  - Error context for troubleshooting
  - Configurable log levels for different environments
  - Integration with existing Phoenix/Ash logging patterns
  """

  require Logger

  @doc """
  Logs Discord interaction events with structured metadata.
  """
  def log_interaction(level, message, interaction, metadata \\ %{}) do
    structured_metadata = %{
      interaction_id: interaction.id,
      interaction_type: interaction.type,
      command_name: get_command_name(interaction),
      user_id: get_user_id(interaction),
      guild_id: Map.get(interaction, :guild_id),
      channel_id: Map.get(interaction, :channel_id),
      component: "interaction_router"
    }

    final_metadata = Map.merge(structured_metadata, metadata)

    Logger.log(level, "[AshDiscord.Interaction] #{message}", Map.to_list(final_metadata))
  end

  @doc """
  Logs Discord command execution with performance timing.
  """
  def log_command_execution(command, interaction, result, execution_time_ms, metadata \\ %{}) do
    {level, status} =
      case result do
        {:ok, _} -> {:info, "success"}
        {:error, _} -> {:error, "failed"}
        _ -> {:info, "completed"}
      end

    structured_metadata = %{
      command: command.name,
      resource: command.resource,
      action: command.action,
      interaction_id: interaction.id,
      user_id: get_user_id(interaction),
      guild_id: Map.get(interaction, :guild_id),
      execution_time_ms: execution_time_ms,
      status: status,
      component: "command_execution"
    }

    final_metadata = Map.merge(structured_metadata, metadata)

    message = "Command #{command.name} #{status} in #{execution_time_ms}ms"
    Logger.log(level, "[AshDiscord.Command] #{message}", Map.to_list(final_metadata))

    # Log slow commands separately for performance monitoring
    if execution_time_ms > 1000 do
      log_slow_operation("command", command.name, execution_time_ms, final_metadata)
    end
  end

  @doc """
  Logs Ash action execution with error details when applicable.
  """
  def log_ash_action(level, action_type, resource, action_name, result, metadata \\ %{}) do
    structured_metadata = %{
      action_type: action_type,
      resource: resource,
      action: action_name,
      component: "ash_action"
    }

    final_metadata = Map.merge(structured_metadata, metadata)

    case result do
      {:ok, _result} ->
        Logger.log(
          level,
          "[AshDiscord.Ash] #{action_type} #{inspect(resource)}.#{action_name} succeeded",
          Map.to_list(final_metadata)
        )

      {:error, error} ->
        error_metadata =
          Map.merge(final_metadata, %{
            error_type: classify_ash_error(error),
            error_details: format_error_for_logging(error)
          })

        Logger.error(
          "[AshDiscord.Ash] #{action_type} #{inspect(resource)}.#{action_name} failed",
          Map.to_list(error_metadata)
        )
    end
  end

  @doc """
  Logs Discord API calls with retry information and rate limit context.
  """
  def log_discord_api_call(method, endpoint, result, attempt \\ 1, metadata \\ %{}) do
    structured_metadata = %{
      discord_api_method: method,
      discord_api_endpoint: endpoint,
      attempt_number: attempt,
      component: "discord_api"
    }

    final_metadata = Map.merge(structured_metadata, metadata)

    case result do
      {:ok, _response} ->
        message =
          if attempt > 1 do
            "Discord API #{method} #{endpoint} succeeded after #{attempt} attempts"
          else
            "Discord API #{method} #{endpoint} succeeded"
          end

        Logger.debug("[AshDiscord.API] #{message}", final_metadata)

      {:error, %{status: status, message: message}} when status in [429, 500, 502, 503, 504] ->
        # Transient errors - log as warning with retry context
        retry_metadata =
          Map.merge(final_metadata, %{
            http_status: status,
            error_message: message,
            transient_error: true
          })

        Logger.warning(
          "[AshDiscord.API] Discord API #{method} #{endpoint} failed (transient)",
          retry_metadata
        )

      {:error, error} ->
        # Permanent errors - log as error
        error_metadata =
          Map.merge(final_metadata, %{
            error_details: format_error_for_logging(error),
            transient_error: false
          })

        Logger.error("[AshDiscord.API] Discord API #{method} #{endpoint} failed", error_metadata)
    end
  end

  @doc """
  Logs consumer event processing with callback filtering information.
  """
  def log_consumer_event(event_type, processing_result \\ nil, metadata \\ %{}) do
    structured_metadata = %{
      event_type: event_type,
      component: "consumer"
    }

    final_metadata = Map.merge(structured_metadata, metadata)

    cond do
      is_nil(processing_result) ->
        Logger.debug("[AshDiscord.Consumer] Processing event #{event_type}", final_metadata)

      processing_result == :ok ->
        Logger.debug(
          "[AshDiscord.Consumer] Event #{event_type} processed successfully",
          final_metadata
        )

      match?({:error, _}, processing_result) ->
        {:error, error} = processing_result

        error_metadata =
          Map.merge(final_metadata, %{
            error_details: format_error_for_logging(error)
          })

        Logger.error(
          "[AshDiscord.Consumer] Event #{event_type} processing failed",
          error_metadata
        )
    end
  end

  @doc """
  Logs configuration resolution with profile and callback information.
  """
  def log_configuration_resolution(profile, enabled_callbacks, config_options, metadata \\ %{}) do
    structured_metadata = %{
      callback_profile: profile,
      enabled_callback_count: length(enabled_callbacks),
      enabled_callbacks: enabled_callbacks,
      config_options: config_options,
      component: "configuration"
    }

    final_metadata = Map.merge(structured_metadata, metadata)

    message =
      "Configuration resolved: #{profile} profile with #{length(enabled_callbacks)} callbacks enabled"

    Logger.info("[AshDiscord.Config] #{message}", final_metadata)
  end

  @doc """
  Logs slow operations for performance monitoring.
  """
  def log_slow_operation(operation_type, operation_name, duration_ms, metadata \\ %{}) do
    structured_metadata = %{
      operation_type: operation_type,
      operation_name: operation_name,
      duration_ms: duration_ms,
      slow_operation: true,
      component: "performance"
    }

    final_metadata = Map.merge(structured_metadata, metadata)

    severity =
      cond do
        duration_ms > 10_000 -> :error
        duration_ms > 5_000 -> :warning
        duration_ms > 1_000 -> :info
        true -> :debug
      end

    Logger.log(
      severity,
      "[AshDiscord.Performance] Slow #{operation_type}: #{operation_name} (#{duration_ms}ms)",
      Map.to_list(final_metadata)
    )
  end

  @doc """
  Logs command registration events with success/failure details.
  """
  def log_command_registration(commands, result, metadata \\ %{}) do
    structured_metadata = %{
      command_count: length(commands),
      command_names: inspect(Enum.map(commands, & &1.name)),
      component: "command_registration"
    }

    final_metadata = Map.merge(structured_metadata, metadata)

    case result do
      {:ok, _} ->
        Logger.info(
          "[AshDiscord.Registration] Successfully registered #{length(commands)} Discord commands",
          Map.to_list(final_metadata)
        )

      {:error, error} ->
        error_metadata =
          Map.merge(final_metadata, %{
            error_details: format_error_for_logging(error)
          })

        Logger.error(
          "[AshDiscord.Registration] Failed to register Discord commands",
          Map.to_list(error_metadata)
        )
    end
  end

  @doc """
  Creates a timing context for measuring operation duration.
  """
  def start_timer(operation_name) do
    %{
      operation: operation_name,
      start_time: System.monotonic_time(:millisecond)
    }
  end

  @doc """
  Completes timing measurement and logs if duration exceeds threshold.
  """
  def end_timer(timer_context, threshold_ms \\ 100, metadata \\ %{}) do
    end_time = System.monotonic_time(:millisecond)
    duration_ms = end_time - timer_context.start_time

    if duration_ms >= threshold_ms do
      log_slow_operation("timed_operation", timer_context.operation, duration_ms, metadata)
    end

    duration_ms
  end

  # Private helper functions

  defp get_command_name(interaction) do
    case Map.get(interaction, :data) do
      %{name: name} when is_binary(name) -> name
      %{name: name} -> inspect(name)
      _ -> "unknown"
    end
  end

  defp get_user_id(interaction) do
    cond do
      Map.has_key?(interaction, :user) && interaction.user ->
        interaction.user.id

      Map.has_key?(interaction, :member) && Map.has_key?(interaction.member, :user) ->
        interaction.member.user.id

      true ->
        "unknown"
    end
  end

  defp classify_ash_error(error) do
    case error do
      %Ash.Error.Invalid{} ->
        "validation"

      %Ash.Error.Forbidden{} ->
        "authorization"

      %Ash.Error.Framework{} ->
        "framework"

      %{__struct__: struct_name} ->
        if struct_name |> to_string() |> String.contains?("NotFound") do
          "not_found"
        else
          "unknown"
        end

      _ ->
        "unknown"
    end
  end

  defp format_error_for_logging(error) do
    case error do
      error when is_exception(error) ->
        %{
          type: error.__struct__,
          message: Exception.message(error)
        }

      error when is_binary(error) ->
        %{message: error}

      error ->
        %{details: inspect(error, pretty: true)}
    end
  end
end
