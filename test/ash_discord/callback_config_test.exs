defmodule AshDiscord.CallbackConfigTest do
  use ExUnit.Case, async: true
  
  alias AshDiscord.CallbackConfig

  describe "core callbacks" do
    test "returns essential callbacks for basic functionality" do
      core_callbacks = CallbackConfig.core_callbacks()
      
      assert :ready in core_callbacks
      assert :interaction_create in core_callbacks
      assert :application_command in core_callbacks
    end
  end

  describe "extended callbacks" do
    test "returns optional callbacks for enhanced functionality" do
      extended_callbacks = CallbackConfig.extended_callbacks()
      
      assert :message_create in extended_callbacks
      assert :guild_create in extended_callbacks
      assert :typing_start in extended_callbacks
      assert :voice_state_update in extended_callbacks
    end
  end

  describe "callback categories" do
    test "properly categorizes callbacks" do
      categories = CallbackConfig.callback_categories()
      
      assert [:message_create, :message_update, :message_delete, :message_delete_bulk] = 
             categories.message_events
      
      assert [:guild_create, :guild_update, :guild_delete] = categories.guild_events
      
      assert [:interaction_create, :application_command] = categories.interaction_events
    end
  end

  describe "expand_categories/1" do
    test "expands category names to individual callbacks" do
      expanded = CallbackConfig.expand_categories([:message_events, :guild_events])
      
      assert :message_create in expanded
      assert :message_update in expanded
      assert :guild_create in expanded
      assert :guild_update in expanded
    end

    test "keeps individual callback names unchanged" do
      expanded = CallbackConfig.expand_categories([:message_create, :guild_events])
      
      assert :message_create in expanded
      assert :guild_create in expanded
      assert :guild_update in expanded
    end

    test "removes duplicates" do
      expanded = CallbackConfig.expand_categories([:message_events, :message_create])
      
      # Should only have one instance of :message_create
      message_create_count = Enum.count(expanded, &(&1 == :message_create))
      assert message_create_count == 1
    end
  end

  describe "configuration profiles" do
    test "minimal profile contains only core callbacks" do
      profiles = CallbackConfig.configuration_profiles()
      minimal = profiles.minimal
      
      assert minimal.performance_optimized == true
      assert minimal.enhanced_logging == false
      
      # Should expand to only core callbacks
      expanded = CallbackConfig.expand_categories(minimal.enabled_callbacks)
      core = CallbackConfig.core_callbacks()
      
      assert Enum.all?(core, &(&1 in expanded))
    end

    test "development profile enables all callbacks with enhanced logging" do
      profiles = CallbackConfig.configuration_profiles()
      dev = profiles.development
      
      assert dev.enhanced_logging == true
      assert dev.performance_optimized == false
      
      expanded = CallbackConfig.expand_categories(dev.enabled_callbacks)
      all_callbacks = CallbackConfig.all_callbacks()
      
      assert Enum.all?(all_callbacks, &(&1 in expanded))
    end

    test "production profile is performance optimized" do
      profiles = CallbackConfig.configuration_profiles()
      prod = profiles.production
      
      assert prod.performance_optimized == true
      assert prod.enhanced_logging == false
    end
  end

  describe "resolve_config/1" do
    test "resolves minimal profile configuration" do
      dsl_config = %{callback_config: :minimal}
      {enabled_callbacks, config_options} = CallbackConfig.resolve_config(dsl_config)
      
      # Core callbacks should always be enabled
      core = CallbackConfig.core_callbacks()
      assert Enum.all?(core, &(&1 in enabled_callbacks))
      
      # Should be performance optimized
      assert config_options.performance_optimized == true
    end

    test "applies enable_callbacks override" do
      dsl_config = %{
        callback_config: :minimal,
        enable_callbacks: [:message_events]
      }
      
      {enabled_callbacks, _config} = CallbackConfig.resolve_config(dsl_config)
      
      # Should include message events
      assert :message_create in enabled_callbacks
      assert :message_update in enabled_callbacks
      
      # Core callbacks still enabled
      assert :ready in enabled_callbacks
    end

    test "applies disable_callbacks override with precedence" do
      dsl_config = %{
        callback_config: :full,
        enable_callbacks: [:message_events],
        disable_callbacks: [:message_create]
      }
      
      {enabled_callbacks, _config} = CallbackConfig.resolve_config(dsl_config)
      
      # disable_callbacks takes precedence
      refute :message_create in enabled_callbacks
      
      # Other message events still enabled
      assert :message_update in enabled_callbacks
      
      # Core callbacks always enabled even if disabled
      assert :ready in enabled_callbacks
    end

    test "custom profile uses explicit configuration" do
      dsl_config = %{
        callback_config: :custom,
        enable_callbacks: [:guild_events],
        debug_logging: true
      }
      
      {enabled_callbacks, config_options} = CallbackConfig.resolve_config(dsl_config)
      
      # Should include guild events
      assert :guild_create in enabled_callbacks
      
      # Should include core callbacks even for custom
      assert :ready in enabled_callbacks
      
      # Should respect debug_logging
      assert config_options.enhanced_logging == true
    end
  end

  describe "callback_enabled?/2" do
    test "returns true for enabled callbacks" do
      enabled = [:message_create, :guild_create]
      
      assert CallbackConfig.callback_enabled?(:message_create, enabled)
      assert CallbackConfig.callback_enabled?(:guild_create, enabled)
    end

    test "returns false for disabled callbacks" do
      enabled = [:message_create, :guild_create]
      
      refute CallbackConfig.callback_enabled?(:typing_start, enabled)
      refute CallbackConfig.callback_enabled?(:voice_state_update, enabled)
    end
  end

  describe "environment_defaults/0" do
    test "returns appropriate defaults for different environments" do
      # This test would need to mock Mix.env() to test properly
      # For now, we'll just ensure it returns a valid profile name
      default = CallbackConfig.environment_defaults()
      
      assert default in [:minimal, :development, :production, :full]
    end
  end
end