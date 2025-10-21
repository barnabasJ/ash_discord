defmodule AshDiscord.DetailedLogTracer do
  @moduledoc """
  A detailed Ash tracer that logs operations to the console.

  ## Usage

  Enable globally:

      config :ash, :tracer, AshDiscord.DetailedLogTracer

  Or per-action:

      TestApp.Discord.message_from_discord!(
        %{data: message},
        tracer: AshDiscord.DetailedLogTracer
      )
  """

  require Logger
  use Ash.Tracer

  @impl true
  def start_span(type, name) do
    context = get_span_context()
    start_time = System.monotonic_time(:microsecond)

    # Get current span stack
    spans = Process.get(:ash_log_tracer_spans, [])

    # Create span ID
    id = make_ref()

    # Determine parent
    parent_id =
      case spans do
        [%{id: parent} | _] -> parent
        _ -> context[:parent_id]
      end

    # Set parent context if this is a root span
    if is_nil(context[:parent_id]) do
      set_span_context(Map.put(context, :parent_id, id))
    end

    # Create new span
    span = %{
      type: type,
      id: id,
      parent_id: parent_id,
      name: name,
      start: start_time,
      metadata: %{}
    }

    # Push span onto stack
    Process.put(:ash_log_tracer_spans, [span | spans])

    # Log span start
    log_span_start(type, name, span)

    :ok
  end

  @impl true
  def stop_span do
    spans = Process.get(:ash_log_tracer_spans, [])

    case spans do
      [span | rest] ->
        Process.put(:ash_log_tracer_spans, rest)

        # Calculate duration
        duration = System.monotonic_time(:microsecond) - span.start
        duration_ms = div(duration, 1000)

        # Update context if this was a root span
        context = get_span_context()

        if context[:parent_id] == span.id do
          set_span_context(Map.put(context, :parent_id, nil))
        end

        # Log span end
        log_span_end(span.type, span.name, span.metadata, duration_ms)

      [] ->
        :ok
    end

    :ok
  end

  @impl true
  def set_metadata(_type, metadata) do
    spans = Process.get(:ash_log_tracer_spans, [])

    case spans do
      [span | rest] ->
        updated_span = Map.update!(span, :metadata, &Map.merge(&1, metadata))
        Process.put(:ash_log_tracer_spans, [updated_span | rest])

      [] ->
        :ok
    end

    :ok
  end

  @impl true
  def get_span_context do
    Process.get(:ash_log_tracer_context, %{})
  end

  @impl true
  def set_span_context(context) do
    Process.put(:ash_log_tracer_context, context)
    :ok
  end

  @impl true
  def set_error(error) do
    spans = Process.get(:ash_log_tracer_spans, [])

    case spans do
      [span | rest] ->
        updated_span = Map.put(span, :error, error)
        Process.put(:ash_log_tracer_spans, [updated_span | rest])

        Logger.error([
          IO.ANSI.red(),
          "✗ ERROR: ",
          IO.ANSI.reset(),
          inspect(error, pretty: true)
        ])

      [] ->
        :ok
    end

    :ok
  end

  # Private logging functions

  defp log_span_start(type, name, _span) do
    Logger.info([
      IO.ANSI.blue(),
      "▶ START ",
      IO.ANSI.reset(),
      IO.ANSI.cyan(),
      format_type(type),
      IO.ANSI.reset(),
      " - ",
      format_span_name(name, type)
    ])
  end

  defp log_span_end(type, name, metadata, duration_ms) do
    color = if duration_ms > 1000, do: IO.ANSI.red(), else: IO.ANSI.green()

    # Extract interesting metadata for Logger
    log_metadata = extract_log_metadata(metadata)

    Logger.info(
      [
        IO.ANSI.green(),
        "✓ END ",
        IO.ANSI.reset(),
        IO.ANSI.cyan(),
        format_type(type),
        IO.ANSI.reset(),
        " - ",
        format_span_name(name, type),
        " (",
        color,
        "#{duration_ms}ms",
        IO.ANSI.reset(),
        ")"
      ],
      log_metadata
    )
  end

  # Extract interesting metadata for Logger
  defp extract_log_metadata(metadata) do
    # Only include keys that Ash actually provides
    interesting_keys = [
      :resource,
      :resource_short_name,
      :action,
      :authorize?,
      :actor,
      :tenant
    ]

    metadata
    |> Map.take(interesting_keys)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.map(fn {k, v} -> {k, format_metadata_value(k, v)} end)
  end

  defp format_metadata_value(_key, value) when is_atom(value), do: value
  defp format_metadata_value(_key, value) when is_binary(value), do: value
  defp format_metadata_value(_key, value) when is_number(value), do: value
  defp format_metadata_value(_key, value) when is_boolean(value), do: value
  defp format_metadata_value(_key, value) when is_list(value), do: "[#{length(value)} items]"
  defp format_metadata_value(_key, value) when is_map(value), do: inspect(value, limit: 20)
  defp format_metadata_value(_key, value), do: inspect(value, limit: 20)

  # Parse and colorize span names like "query:webhook:read"
  defp format_span_name(name, type) when is_binary(name) do
    case String.split(name, ":") do
      # Single part - just return it
      [single] ->
        [IO.ANSI.white(), single, IO.ANSI.reset()]

      # Multiple parts - check if first part matches type
      [first | rest] ->
        type_str = format_type(type) |> to_string()

        # Skip first part if it matches the type (redundant)
        parts_to_show =
          if String.downcase(first) == String.downcase(type_str) or
               String.contains?(type_str, String.downcase(first)) do
            rest
          else
            [first | rest]
          end

        # Color each part differently
        parts_to_show
        |> Enum.with_index()
        |> Enum.map(fn {part, idx} ->
          color =
            case rem(idx, 3) do
              0 -> IO.ANSI.light_green()
              1 -> IO.ANSI.light_cyan()
              2 -> IO.ANSI.light_yellow()
            end

          [color, part, IO.ANSI.reset()]
        end)
        |> Enum.intersperse([IO.ANSI.white(), ":", IO.ANSI.reset()])
    end
  end

  defp format_span_name(name, _type) do
    [IO.ANSI.white(), to_string(name), IO.ANSI.reset()]
  end

  defp format_type(type) when is_atom(type), do: inspect(type)
  defp format_type({:custom, name}), do: "custom:#{name}"
  defp format_type(type), do: inspect(type)
end
