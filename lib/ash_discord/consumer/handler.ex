defmodule AshDiscord.Consumer.Handler do
  @moduledoc """
  Main event handler for routing Discord events to callbacks or handler modules.
  """

  require Logger

  @spec handle_event(consumer :: module(), event_payload_ws :: Nostrum.Consumer.event()) :: any()
  def handle_event(consumer, {event, payload, ws_state}) do
    {handler_mod, handler_fun, resource_type, callback} =
      AshDiscord.Consumer.EventMap.handler_for(event)

    if function_exported?(consumer, callback, 3) do
      context = build_context(consumer, nil, payload)
      Logger.info("Handling #{event} with #{consumer}.#{callback}/3")

      case apply(consumer, callback, [payload, ws_state, context]) do
        {:error, _} = error ->
          Logger.error("Error handling #{event} in #{consumer}.#{callback}/3: #{inspect(error)}")
          error

        other ->
          Logger.info("Successfully handled #{event} in #{consumer}.#{callback}/3")
          other
      end
    else
      resource = get_resource(consumer, resource_type)

      if resource do
        context = build_context(consumer, resource, payload)

        Logger.info("Handling #{event} with #{handler_mod}.#{handler_fun}/3")

        case apply(handler_mod, handler_fun, [payload, ws_state, context]) do
          {:error, _} = error ->
            Logger.error(
              "Error handling #{event} in #{handler_mod}.#{handler_fun}/3: #{inspect(error)}"
            )

            error

          other ->
            Logger.info("Successfully handled #{event} in #{handler_mod}.#{handler_fun}/3")
            other
        end
      else
        Logger.debug("Skipping #{event} - no #{resource_type} configured")
        :ok
      end
    end
  end

  @spec get_resource(consumer :: module(), resource_type :: atom()) :: Ash.Resource.t() | nil
  defp get_resource(consumer, resource_type) do
    info_function = String.to_existing_atom("ash_discord_consumer_#{resource_type}")

    case apply(AshDiscord.Consumer.Info, info_function, [consumer]) do
      {:ok, resource} -> resource
      :error -> nil
    end
  rescue
    _ -> nil
  end

  @spec build_context(
          consumer :: module(),
          resource :: Ash.Resource.t() | nil,
          payload :: AshDiscord.Consumer.Payload.t()
        ) :: AshDiscord.Context.t()
  defp build_context(consumer, resource, payload) do
    user = AshDiscord.Context.extract_user(payload)
    guild = AshDiscord.Context.extract_guild(payload)

    %AshDiscord.Context{
      consumer: consumer,
      resource: resource,
      guild: guild,
      user: user
    }
  end
end
