defmodule AshDiscord.Consumer.Handler do
  require Logger
  @spec handle_event(consumer :: module(), event_payload_ws :: Nostrum.Consumer.event()) :: any()
  def handle_event(consumer, {event, payload, ws_state}) do
    callback = callback(event)

    if function_exported?(consumer, String.to_existing_atom(callback), 3) do
      Logger.info("Handling #{event} with #{consumer}.#{callback}/3")

      case apply(consumer, callback, [payload, ws_state]) do
        {:error, _} = error ->
          Logger.error("Error handling #{event} in #{consumer}.#{callback}/3: #{inspect(error)}")
          error

        other ->
          Logger.info("Successfully handled #{event} in #{consumer}.#{callback}/3")
          other
      end
    else
      {mod, fun} = handler_mf(event)
      Logger.info("Handling #{event} with #{mod}.#{fun}/3")

      case apply(mod, fun, [consumer, payload, ws_state]) do
        {:error, _} = error ->
          Logger.error("Error handling #{event} in #{mod}.#{fun}/3: #{inspect(error)}")
          error

        other ->
          Logger.info("Successfully handled #{event} in #{mod}.#{fun}/3")
          other
      end
    end
  end

  def callback(event) do
    "handle_" <> String.downcase(Atom.to_string(event))
  end

  defp handler_mf(event) when is_atom(event) do
    String.split(Atom.to_string(event), "_")
    |> handler_mf([])
  end

  defp handler_mf([function | []], module) do
    {
      module
      |> Enum.reverse()
      |> Enum.map(&String.capitalize/1)
      |> then(&["AshDiscord", "Consumer", "Handler" | &1])
      |> Module.concat(),
      String.to_existing_atom(String.downcase(function))
    }
  end

  defp handler_mf([part | rest], module) do
    handler_mf(rest, [part | module])
  end
end
