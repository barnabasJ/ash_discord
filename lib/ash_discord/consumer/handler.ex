defmodule AshDiscord.Consumer.Handler do
  @moduledoc """
  Main event handler for routing Discord events to callbacks or handler modules.
  """

  require Logger

  @spec handle_event(consumer :: module(), event_payload_ws :: Nostrum.Consumer.event()) :: any()
  def handle_event(consumer, {event, payload, ws_state}) do
    case AshDiscord.Consumer.EventMap.handler_for(event) do
      nil ->
        Logger.warning(
          "Skipping #{event} - event not supported (not documented in official Discord API)"
        )

        :ok

      {handler_mod, handler_fun, resource_type, callback, payload_module} ->
        # Transform Nostrum payload to AshDiscord TypedStruct
        {:ok, transformed_payload} = payload_module.new(payload)

        handle_supported_event(
          consumer,
          event,
          transformed_payload,
          ws_state,
          handler_mod,
          handler_fun,
          resource_type,
          callback
        )
    end
  end

  defp handle_supported_event(
         consumer,
         event,
         transformed_payload,
         ws_state,
         handler_mod,
         handler_fun,
         _resource_type,
         callback
       ) do
    if function_exported?(consumer, callback, 3) do
      context = build_context(consumer, nil, transformed_payload)
      Logger.info("Handling #{event} with #{consumer}.#{callback}/3")

      case apply(consumer, callback, [transformed_payload, ws_state, context]) do
        {:error, _} = error ->
          Logger.error("Error handling #{event} in #{consumer}.#{callback}/3: #{inspect(error)}")
          error

        other ->
          Logger.info("Successfully handled #{event} in #{consumer}.#{callback}/3")
          other
      end
    else
      resource = get_resource(consumer, event)

      if resource do
        context = build_context(consumer, resource, transformed_payload)

        Logger.info("Handling #{event} with #{handler_mod}.#{handler_fun}/3")

        case apply(handler_mod, handler_fun, [transformed_payload, ws_state, context]) do
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
        Logger.debug("Skipping #{event} - no resource configured to handle this event")
        :ok
      end
    end
  end

  @spec get_resource(consumer :: module(), event :: atom()) :: Ash.Resource.t() | nil
  defp get_resource(consumer, event) do
    # Get the discovered event handlers map from the consumer
    case Spark.Dsl.Extension.get_persisted(consumer, :discord_event_handlers) do
      nil ->
        # No event handlers discovered (or consumer not compiled with new transformer yet)
        Logger.debug("No event handlers discovered for #{consumer}")
        nil

      event_handlers when is_map(event_handlers) ->
        # Look up the resource for this specific event
        case Map.get(event_handlers, event) do
          {resource, _action} when is_atom(resource) ->
            resource

          nil ->
            Logger.debug("No handler configured for event #{event}")
            nil
        end
    end
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
