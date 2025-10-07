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

  @doc """
  Invokes a configured action on a resource based on the event, dynamically selecting
  the appropriate invocation method based on the action type.

  Uses bulk operations by default for better performance, even for single records.

  ## Parameters
    - resource: The Ash resource module to invoke the action on
    - event: The Discord event atom (e.g., :MESSAGE_CREATE)
    - payload: The event payload containing attributes
    - context: The AshDiscord.Context struct containing actor, tenant, etc.

  ## Returns
    - `{:ok, result}` on successful action invocation
    - `{:error, reason}` on failure

  ## Examples

      iex> invoke_configured_action(MyApp.Message, :MESSAGE_CREATE, payload, context)
      {:ok, %MyApp.Message{}}

      iex> invoke_configured_action(MyApp.Message, :MESSAGE_DELETE, payload, context)
      {:ok, %MyApp.Message{}}
  """
  @spec invoke_configured_action(
          resource :: Ash.Resource.t(),
          event :: atom(),
          payload :: map(),
          context :: AshDiscord.Context.t()
        ) :: {:ok, any()} | {:error, any()}
  def invoke_configured_action(resource, event, payload, context) do
    with {:ok, action_name} <- get_configured_action(resource, event),
         {:ok, action} <- fetch_action(resource, action_name) do
      invoke_action_by_type(resource, action, payload, context)
    end
  end

  @spec get_configured_action(resource :: Ash.Resource.t(), event :: atom()) ::
          {:ok, atom()} | {:error, String.t()}
  defp get_configured_action(resource, event) do
    case AshDiscord.Resource.Info.discord_event_action(resource, event) do
      {:ok, action_name} ->
        {:ok, action_name}

      :error ->
        {:error, "No action configured for event #{event} on resource #{inspect(resource)}"}
    end
  end

  @spec fetch_action(resource :: Ash.Resource.t(), action_name :: atom()) ::
          {:ok, Ash.Resource.Actions.action()} | {:error, String.t()}
  defp fetch_action(resource, action_name) do
    case Ash.Resource.Info.action(resource, action_name) do
      nil ->
        {:error, "Action #{action_name} not found on resource #{inspect(resource)}"}

      action ->
        {:ok, action}
    end
  end

  @spec invoke_action_by_type(
          resource :: Ash.Resource.t(),
          action :: Ash.Resource.Actions.action(),
          payload :: map(),
          context :: AshDiscord.Context.t()
        ) :: {:ok, any()} | {:error, any()}
  defp invoke_action_by_type(resource, action, payload, context) do
    opts = context_to_opts(context)

    case action.type do
      :create ->
        invoke_bulk_create(resource, action, payload, opts)

      :update ->
        invoke_bulk_update(resource, action, payload, opts)

      :destroy ->
        invoke_bulk_destroy(resource, action, payload, opts)

      :read ->
        invoke_read_action(resource, action, payload, opts)

      :action ->
        invoke_generic_action(resource, action, payload, opts)

      unknown_type ->
        {:error, "Unknown action type: #{unknown_type}"}
    end
  end

  @spec invoke_bulk_create(
          resource :: Ash.Resource.t(),
          action :: Ash.Resource.Actions.action(),
          attributes :: map(),
          opts :: keyword()
        ) :: {:ok, Ash.Resource.record()} | {:error, any()}
  defp invoke_bulk_create(resource, action, attributes, opts) do
    Logger.debug("Invoking bulk create action #{action.name} on #{inspect(resource)}")

    result =
      Ash.bulk_create(
        [attributes],
        resource,
        action.name,
        Keyword.merge(opts,
          return_records?: true,
          return_errors?: true,
          stop_on_error?: true
        )
      )

    format_bulk_result(result, :single)
  end

  @spec invoke_bulk_update(
          resource :: Ash.Resource.t(),
          action :: Ash.Resource.Actions.action(),
          attributes :: map(),
          opts :: keyword()
        ) :: {:ok, Ash.Resource.record()} | {:error, any()}
  defp invoke_bulk_update(resource, action, attributes, opts) do
    Logger.debug("Invoking bulk update action #{action.name} on #{inspect(resource)}")

    with {:ok, query} <- build_update_query(resource, attributes, opts) do
      result =
        Ash.bulk_update(
          query,
          action.name,
          attributes,
          Keyword.merge(opts,
            return_records?: true,
            return_errors?: true,
            stop_on_error?: true
          )
        )

      format_bulk_result(result, :single)
    end
  end

  @spec invoke_bulk_destroy(
          resource :: Ash.Resource.t(),
          action :: Ash.Resource.Actions.action(),
          attributes :: map(),
          opts :: keyword()
        ) :: {:ok, Ash.Resource.record()} | {:error, any()}
  defp invoke_bulk_destroy(resource, action, attributes, opts) do
    require Ash.Query

    Logger.debug("Invoking bulk destroy action #{action.name} on #{inspect(resource)}")

    with {:ok, query} <- build_destroy_query(resource, attributes, opts) do
      result =
        Ash.bulk_destroy(
          query,
          action.name,
          attributes,
          Keyword.merge(opts,
            return_records?: true,
            return_errors?: true,
            stop_on_error?: true
          )
        )

      format_bulk_result(result, :single)
    end
  end

  @spec invoke_read_action(
          resource :: Ash.Resource.t(),
          action :: Ash.Resource.Actions.action(),
          filters :: map(),
          opts :: keyword()
        ) :: {:ok, list(Ash.Resource.record())} | {:error, any()}
  defp invoke_read_action(resource, action, filters, opts) do
    require Ash.Query

    Logger.debug("Invoking read action #{action.name} on #{inspect(resource)}")

    resource
    |> Ash.Query.for_read(action.name, filters, opts)
    |> Ash.read(opts)
  end

  @spec invoke_generic_action(
          resource :: Ash.Resource.t(),
          action :: Ash.Resource.Actions.action(),
          arguments :: map(),
          opts :: keyword()
        ) :: {:ok, any()} | {:error, any()}
  defp invoke_generic_action(resource, action, arguments, opts) do
    Logger.debug("Invoking generic action #{action.name} on #{inspect(resource)}")

    resource
    |> Ash.ActionInput.for_action(action.name, arguments, opts)
    |> Ash.run_action(opts)
  end

  @spec build_update_query(
          resource :: Ash.Resource.t(),
          attributes :: map(),
          opts :: keyword()
        ) :: {:ok, Ash.Query.t()} | {:error, any()}
  defp build_update_query(resource, %{id: id}, opts) do
    require Ash.Query

    case Ash.get(resource, id, opts) do
      {:ok, record} ->
        {:ok, [record]}

      {:error, _} = error ->
        Logger.error("Failed to fetch record with id #{id} for update: #{inspect(error)}")
        error
    end
  end

  defp build_update_query(resource, attributes, _opts) do
    Logger.error(
      "No identifier provided for update action on #{inspect(resource)}: #{inspect(attributes)}"
    )

    {:error, "No identifier provided for update action"}
  end

  @spec build_destroy_query(
          resource :: Ash.Resource.t(),
          attributes :: map(),
          opts :: keyword()
        ) :: {:ok, Ash.Query.t()} | {:error, any()}
  defp build_destroy_query(resource, %{id: id}, opts) do
    require Ash.Query

    case Ash.get(resource, id, opts) do
      {:ok, record} ->
        {:ok, [record]}

      {:error, _} = error ->
        Logger.error("Failed to fetch record with id #{id} for destroy: #{inspect(error)}")
        error
    end
  end

  defp build_destroy_query(resource, attributes, _opts) do
    Logger.error(
      "No identifier provided for destroy action on #{inspect(resource)}: #{inspect(attributes)}"
    )

    {:error, "No identifier provided for destroy action"}
  end

  @spec format_bulk_result(Ash.BulkResult.t(), :single | :bulk) ::
          {:ok, any()} | {:error, any()}
  defp format_bulk_result(%Ash.BulkResult{status: :success, records: [record]}, :single) do
    {:ok, record}
  end

  defp format_bulk_result(%Ash.BulkResult{status: :success, records: records}, :bulk) do
    {:ok, records}
  end

  defp format_bulk_result(%Ash.BulkResult{status: :error, errors: [error | _]}, :single) do
    {:error, error}
  end

  defp format_bulk_result(%Ash.BulkResult{status: :error, errors: errors}, :bulk) do
    {:error, errors}
  end

  defp format_bulk_result(%Ash.BulkResult{status: :partial_success} = result, _) do
    Logger.warning(
      "Partial success: #{length(result.records)} succeeded, #{result.error_count} failed"
    )

    {:error, result.errors}
  end

  @spec context_to_opts(context :: AshDiscord.Context.t()) :: keyword()
  defp context_to_opts(context) do
    []
    |> maybe_add_opt(:actor, context.user)
    |> maybe_add_opt(:tenant, context.guild)
  end

  @spec maybe_add_opt(opts :: keyword(), key :: atom(), value :: any()) :: keyword()
  defp maybe_add_opt(opts, _key, nil), do: opts
  defp maybe_add_opt(opts, key, value), do: Keyword.put(opts, key, value)
end
