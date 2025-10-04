defmodule AshDiscord.Consumer.Handler do
  @moduledoc """
  Main event handler for routing Discord events to callbacks or handler modules.
  """

  require Logger

  @spec handle_event(consumer :: module(), event_payload_ws :: Nostrum.Consumer.event()) :: any()
  def handle_event(consumer, {event, payload, ws_state}) do
    {handler_mod, handler_fun, resource_type, callback, payload_module} =
      AshDiscord.Consumer.EventMap.handler_for(event)

    # Transform Nostrum payload to AshDiscord TypedStruct
    transformed_payload = payload_module.new(payload)

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
      resource = get_resource(consumer, resource_type)

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
        Logger.debug("Skipping #{event} - no #{resource_type} configured")
        :ok
      end
    end
  end

  @spec get_resource(consumer :: module(), resource_type :: atom()) :: Ash.Resource.t() | nil
  defp get_resource(consumer, resource_type) do
    resource_type
    |> case do
      :channel_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_channel_resource(consumer)

      :guild_member_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_guild_member_resource(consumer)

      :guild_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_guild_resource(consumer)

      :invite_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_invite_resource(consumer)

      :interaction_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_interaction_resource(consumer)

      :presence_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_presence_resource(consumer)

      :message_reaction_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_message_reaction_resource(consumer)

      :message_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_message_resource(consumer)

      :role_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_role_resource(consumer)

      :typing_indicator_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_typing_indicator_resource(consumer)

      :user_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_user_resource(consumer)

      :voice_state_resource ->
        AshDiscord.Consumer.Info.ash_discord_consumer_voice_state_resource(consumer)

      :ready_resource ->
        # Ready is a special case with no associated resource
        :error

      _ ->
        :error
    end
    |> case do
      {:ok, resource} -> resource
      :error -> nil
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
