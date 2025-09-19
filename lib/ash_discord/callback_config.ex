defmodule AshDiscord.CallbackConfig do
  @moduledoc """
  Configuration manager for selective callback processing in AshDiscord consumers.
  
  This module handles:
  - Predefined configuration profiles (development, production, minimal, full)
  - Callback categorization (core vs extended callbacks)
  - Individual callback enabling/disabling
  - Environment-aware defaults
  - Performance optimization through selective processing
  """

  @doc """
  Core callbacks that are essential for basic Discord bot functionality.
  These callbacks are always enabled regardless of configuration.
  """
  def core_callbacks do
    [
      :ready,
      :interaction_create,
      :application_command
    ]
  end

  @doc """
  Extended callbacks that provide additional functionality but can be disabled for performance.
  """
  def extended_callbacks do
    [
      :message_create, :message_update, :message_delete, :message_delete_bulk,
      :message_reaction_add, :message_reaction_remove, :message_reaction_remove_all,
      :guild_create, :guild_update, :guild_delete,
      :guild_role_create, :guild_role_update, :guild_role_delete,
      :guild_member_add, :guild_member_update, :guild_member_remove,
      :channel_create, :channel_update, :channel_delete,
      :voice_state_update, :typing_start, :invite_create, :invite_delete,
      :unknown_event
    ]
  end

  @doc """
  All available callback names.
  """
  def all_callbacks do
    core_callbacks() ++ extended_callbacks()
  end

  @doc """
  Callback categories for easier configuration.
  """
  def callback_categories do
    %{
      message_events: [:message_create, :message_update, :message_delete, :message_delete_bulk],
      reaction_events: [:message_reaction_add, :message_reaction_remove, :message_reaction_remove_all],
      guild_events: [:guild_create, :guild_update, :guild_delete],
      role_events: [:guild_role_create, :guild_role_update, :guild_role_delete],
      member_events: [:guild_member_add, :guild_member_update, :guild_member_remove],
      channel_events: [:channel_create, :channel_update, :channel_delete],
      interaction_events: [:interaction_create, :application_command],
      voice_events: [:voice_state_update],
      typing_events: [:typing_start],
      invite_events: [:invite_create, :invite_delete],
      unknown_events: [:unknown_event],
      core_events: core_callbacks()
    }
  end

  @doc """
  Predefined configuration profiles.
  """
  def configuration_profiles do
    %{
      minimal: %{
        enabled_callbacks: core_callbacks(),
        enhanced_logging: false,
        performance_optimized: true
      },
      production: %{
        enabled_callbacks: core_callbacks() ++ [:message_events, :guild_events, :interaction_events],
        enhanced_logging: false,
        performance_optimized: true
      },
      development: %{
        enabled_callbacks: all_callbacks(),
        enhanced_logging: true,
        performance_optimized: false
      },
      full: %{
        enabled_callbacks: all_callbacks(),
        enhanced_logging: false,
        performance_optimized: false
      }
    }
  end

  @doc """
  Resolves the final callback configuration based on DSL settings.
  
  Takes into account:
  1. Predefined profiles (callback_config)
  2. Explicit enable_callbacks list
  3. Explicit disable_callbacks list (takes precedence)
  4. Environment defaults
  
  Returns a tuple of {enabled_callbacks, config_options}.
  Raises AshDiscord.Errors.ConfigurationError for invalid configuration.
  """
  def resolve_config(dsl_config) do
    with :ok <- validate_config(dsl_config) do
      profile = get_profile(dsl_config)
      base_callbacks = resolve_base_callbacks(profile, dsl_config)
      final_callbacks = apply_overrides(base_callbacks, dsl_config)
      config_options = build_config_options(profile, dsl_config)
      
      {final_callbacks, config_options}
    else
      {:error, error} ->
        raise error
    end
  end

  @doc """
  Checks if a specific callback is enabled in the resolved configuration.
  """
  def callback_enabled?(callback_name, enabled_callbacks) do
    callback_name in enabled_callbacks
  end

  @doc """
  Expands callback categories into individual callback names.
  """
  def expand_categories(callback_list) when is_list(callback_list) do
    categories = callback_categories()
    
    Enum.flat_map(callback_list, fn item ->
      case Map.get(categories, item) do
        nil -> [item]  # Individual callback name
        category_callbacks -> category_callbacks
      end
    end)
    |> Enum.uniq()
  end

  @doc """
  Gets environment-aware defaults based on Mix.env().
  """
  def environment_defaults do
    case Mix.env() do
      :prod -> :production
      :dev -> :development  
      :test -> :minimal
      _ -> :full
    end
  end

  # Private functions

  defp get_profile(dsl_config) do
    profile_name = Map.get(dsl_config, :callback_config, environment_defaults())
    
    case Map.get(configuration_profiles(), profile_name) do
      nil -> 
        # Custom profile - use explicit configuration
        %{
          enabled_callbacks: [],
          enhanced_logging: Map.get(dsl_config, :debug_logging, false),
          performance_optimized: false
        }
      profile -> profile
    end
  end

  defp resolve_base_callbacks(profile, dsl_config) do
    case Map.get(dsl_config, :callback_config) do
      :custom ->
        # For custom config, start with core callbacks only
        core_callbacks()
      _ ->
        # For predefined profiles, use profile's enabled callbacks
        expand_categories(profile.enabled_callbacks)
    end
  end

  defp apply_overrides(base_callbacks, dsl_config) do
    # Start with base callbacks
    callbacks = base_callbacks
    
    # Apply enable_callbacks (additive)
    callbacks = 
      case Map.get(dsl_config, :enable_callbacks) do
        nil -> callbacks
        enable_list -> 
          enabled_expanded = expand_categories(enable_list)
          Enum.uniq(callbacks ++ enabled_expanded)
      end
    
    # Apply disable_callbacks (subtractive, takes precedence)
    callbacks =
      case Map.get(dsl_config, :disable_callbacks) do
        nil -> callbacks
        disable_list ->
          disabled_expanded = expand_categories(disable_list)
          callbacks -- disabled_expanded
      end
    
    # Always ensure core callbacks are enabled
    Enum.uniq(callbacks ++ core_callbacks())
  end

  defp build_config_options(profile, dsl_config) do
    %{
      enhanced_logging: Map.get(dsl_config, :debug_logging, profile.enhanced_logging),
      performance_optimized: Map.get(profile, :performance_optimized, false),
      store_bot_messages: Map.get(dsl_config, :store_bot_messages, false),
      auto_create_users: Map.get(dsl_config, :auto_create_users, true)
    }
  end

  # Configuration validation functions

  defp validate_config(dsl_config) do
    with :ok <- validate_callback_config(dsl_config),
         :ok <- validate_callback_lists(dsl_config),
         :ok <- validate_boolean_options(dsl_config) do
      :ok
    end
  end

  defp validate_callback_config(dsl_config) do
    config_name = Map.get(dsl_config, :callback_config)

    cond do
      is_nil(config_name) ->
        # Use environment defaults - always valid
        :ok

      config_name in [:minimal, :production, :development, :full, :custom] ->
        :ok

      true ->
        available_configs = Map.keys(configuration_profiles()) ++ [:custom]
        error = AshDiscord.Errors.invalid_callback_config_error(config_name, available_configs)
        {:error, error}
    end
  end

  defp validate_callback_lists(dsl_config) do
    enable_callbacks = Map.get(dsl_config, :enable_callbacks, [])
    disable_callbacks = Map.get(dsl_config, :disable_callbacks, [])

    all_valid_callbacks = all_callbacks() ++ Map.keys(callback_categories())

    with :ok <- validate_callback_list(enable_callbacks, all_valid_callbacks, :enable_callbacks),
         :ok <- validate_callback_list(disable_callbacks, all_valid_callbacks, :disable_callbacks) do
      validate_callback_conflicts(enable_callbacks, disable_callbacks)
    end
  end

  defp validate_callback_list(nil, _valid_callbacks, _list_name), do: :ok
  
  defp validate_callback_list(callback_list, valid_callbacks, list_name) when is_list(callback_list) do
    invalid_callbacks = callback_list -- valid_callbacks

    if Enum.empty?(invalid_callbacks) do
      :ok
    else
      error = AshDiscord.Errors.ConfigurationError.exception(
        message: "Invalid callbacks in #{list_name}: #{inspect(invalid_callbacks)}",
        context: %{
          invalid: invalid_callbacks,
          valid_callbacks: valid_callbacks,
          valid_categories: Map.keys(callback_categories())
        },
        suggestions: [
          "Use valid callback names: #{Enum.join(all_callbacks(), ", ")}",
          "Use callback categories: #{Enum.join(Map.keys(callback_categories()), ", ")}",
          "Check for typos in callback names",
          "Refer to documentation for complete callback list"
        ],
        examples: [
          "enable_callbacks: [:message_events, :guild_events]",
          "disable_callbacks: [:typing_start, :voice_state_update]"
        ]
      )
      {:error, error}
    end
  end

  defp validate_callback_conflicts(_enable_callbacks, nil), do: :ok
  
  defp validate_callback_conflicts(_enable_callbacks, disable_callbacks) when is_list(disable_callbacks) do
    # Check for explicit core callback disabling attempts
    core_disabled = Enum.filter(disable_callbacks, &(&1 in core_callbacks()))

    if Enum.empty?(core_disabled) do
      :ok
    else
      error = AshDiscord.Errors.ConfigurationError.exception(
        message: "Cannot disable core callbacks: #{inspect(core_disabled)}",
        context: %{
          attempted_disable: core_disabled,
          core_callbacks: core_callbacks()
        },
        suggestions: [
          "Remove core callbacks from disable_callbacks list",
          "Core callbacks are essential for Discord bot operation",
          "Use callback_config: :minimal for minimal callback set"
        ],
        examples: [
          "disable_callbacks: [:typing_start, :voice_state_update]  # OK",
          "disable_callbacks: [:message_events, :guild_events]      # OK"
        ]
      )
      {:error, error}
    end
  end

  defp validate_boolean_options(dsl_config) do
    boolean_options = [:debug_logging, :auto_create_users, :store_bot_messages]

    invalid_booleans = 
      Enum.filter(boolean_options, fn option ->
        value = Map.get(dsl_config, option)
        not is_nil(value) and not is_boolean(value)
      end)

    if Enum.empty?(invalid_booleans) do
      :ok
    else
      error = AshDiscord.Errors.ConfigurationError.exception(
        message: "Boolean options must be true or false: #{inspect(invalid_booleans)}",
        context: %{
          invalid_options: invalid_booleans,
          provided_values: Map.take(dsl_config, invalid_booleans)
        },
        suggestions: [
          "Use true or false for boolean options",
          "Remove option to use default value",
          "Check for typos (True vs true, False vs false)"
        ],
        examples: [
          "debug_logging: true",
          "auto_create_users: false",
          "store_bot_messages: true"
        ]
      )
      {:error, error}
    end
  end
end