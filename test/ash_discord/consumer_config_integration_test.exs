defmodule AshDiscord.ConsumerConfigIntegrationTest do
  use ExUnit.Case, async: true

  defmodule MinimalConfigConsumer do
    use AshDiscord.Consumer,
      domains: [],
      callback_config: :minimal
  end

  defmodule ProductionConfigConsumer do
    use AshDiscord.Consumer,
      domains: [],
      callback_config: :production,
      disable_callbacks: [:voice_state_update, :typing_start]
  end

  defmodule DevelopmentConfigConsumer do
    use AshDiscord.Consumer,
      domains: [],
      callback_config: :development,
      debug_logging: true
  end

  defmodule CustomConfigConsumer do
    use AshDiscord.Consumer,
      domains: [],
      callback_config: :custom,
      enable_callbacks: [:message_events, :guild_events],
      disable_callbacks: [:message_delete],
      debug_logging: false,
      auto_create_users: false,
      store_bot_messages: true
  end

  describe "minimal configuration profile" do
    test "includes only core callbacks" do
      enabled = MinimalConfigConsumer.enabled_callbacks()
      core = AshDiscord.CallbackConfig.core_callbacks()
      
      # All core callbacks should be enabled
      assert Enum.all?(core, &(&1 in enabled))
      
      # Should have minimal additional callbacks
      assert length(enabled) <= length(core) + 2  # Allow minimal extras
      
      # Specific extended callbacks should be disabled
      refute :typing_start in enabled
      refute :voice_state_update in enabled
    end

    test "has performance optimizations enabled" do
      config = MinimalConfigConsumer.callback_config()
      
      assert config.performance_optimized == true
      assert config.enhanced_logging == false
    end

    test "callback_enabled? works for minimal config" do
      # Core callbacks should be enabled
      assert MinimalConfigConsumer.callback_enabled?(:ready)
      assert MinimalConfigConsumer.callback_enabled?(:interaction_create)
      assert MinimalConfigConsumer.callback_enabled?(:application_command)
      
      # Extended callbacks should be disabled
      refute MinimalConfigConsumer.callback_enabled?(:typing_start)
      refute MinimalConfigConsumer.callback_enabled?(:voice_state_update)
      refute MinimalConfigConsumer.callback_enabled?(:invite_create)
    end
  end

  describe "production configuration profile" do
    test "includes core callbacks plus essential business callbacks" do
      enabled = ProductionConfigConsumer.enabled_callbacks()
      core = AshDiscord.CallbackConfig.core_callbacks()
      
      # All core callbacks should be enabled
      assert Enum.all?(core, &(&1 in enabled))
      
      # Should include essential business callbacks
      assert :message_create in enabled
      assert :guild_create in enabled
      
      # Should respect disable overrides
      refute :voice_state_update in enabled
      refute :typing_start in enabled
    end

    test "has performance optimizations with essential features" do
      config = ProductionConfigConsumer.callback_config()
      
      assert config.performance_optimized == true
      assert config.enhanced_logging == false
      assert config.auto_create_users == true  # Default value
    end
  end

  describe "development configuration profile" do
    test "includes all callbacks for debugging" do
      enabled = DevelopmentConfigConsumer.enabled_callbacks()
      all_callbacks = AshDiscord.CallbackConfig.all_callbacks()
      
      # Should include all callbacks for development
      assert Enum.all?(all_callbacks, &(&1 in enabled))
    end

    test "has enhanced logging enabled" do
      config = DevelopmentConfigConsumer.callback_config()
      
      assert config.enhanced_logging == true
      assert config.performance_optimized == false
    end
  end

  describe "custom configuration profile" do
    test "respects explicit enable/disable configuration" do
      enabled = CustomConfigConsumer.enabled_callbacks()
      
      # Core callbacks always enabled
      assert :ready in enabled
      assert :interaction_create in enabled
      
      # Message events enabled (except disabled ones)
      assert :message_create in enabled
      assert :message_update in enabled
      refute :message_delete in enabled  # Explicitly disabled
      
      # Guild events enabled
      assert :guild_create in enabled
      assert :guild_update in enabled
      
      # Events not explicitly enabled should not be included
      # (except core callbacks which are always enabled)
      refute :typing_start in enabled
      refute :voice_state_update in enabled
      refute :invite_create in enabled
    end

    test "respects custom configuration options" do
      config = CustomConfigConsumer.callback_config()
      
      assert config.enhanced_logging == false
      assert config.auto_create_users == false
      assert config.store_bot_messages == true
    end

    test "callback_enabled? works for custom config" do
      assert CustomConfigConsumer.callback_enabled?(:message_create)
      assert CustomConfigConsumer.callback_enabled?(:guild_create)
      refute CustomConfigConsumer.callback_enabled?(:message_delete)
      refute CustomConfigConsumer.callback_enabled?(:typing_start)
    end
  end

  describe "configuration validation" do
    test "all configurations include core callbacks" do
      consumers = [
        MinimalConfigConsumer,
        ProductionConfigConsumer,
        DevelopmentConfigConsumer,
        CustomConfigConsumer
      ]
      
      core_callbacks = AshDiscord.CallbackConfig.core_callbacks()
      
      for consumer <- consumers do
        enabled = consumer.enabled_callbacks()
        assert Enum.all?(core_callbacks, &(&1 in enabled)), 
               "#{consumer} should include all core callbacks"
      end
    end

    test "callback configuration is computed at compile time" do
      # Test that the configuration is available as module attributes
      # and doesn't require runtime computation
      
      assert is_list(MinimalConfigConsumer.enabled_callbacks())
      assert is_map(MinimalConfigConsumer.callback_config())
      
      # Configuration should be the same on multiple calls (cached)
      config1 = MinimalConfigConsumer.callback_config()
      config2 = MinimalConfigConsumer.callback_config()
      assert config1 == config2
      
      enabled1 = MinimalConfigConsumer.enabled_callbacks()
      enabled2 = MinimalConfigConsumer.enabled_callbacks() 
      assert enabled1 == enabled2
    end
  end

  describe "category expansion" do
    test "message_events category includes all message callbacks" do
      enabled = CustomConfigConsumer.enabled_callbacks()
      
      # Should include message event callbacks (except disabled ones)
      message_events = [:message_create, :message_update, :message_delete, :message_delete_bulk]
      
      assert :message_create in enabled
      assert :message_update in enabled
      refute :message_delete in enabled  # Explicitly disabled
      assert :message_delete_bulk in enabled
    end
  end
end