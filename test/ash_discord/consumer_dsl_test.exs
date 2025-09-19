defmodule AshDiscord.ConsumerDslTest do
  use ExUnit.Case, async: true

  defmodule TestConsumer do
    use AshDiscord.Consumer,
      domains: [],
      callback_config: :minimal,
      enable_callbacks: [:message_events],
      disable_callbacks: [:typing_start],
      debug_logging: true,
      auto_create_users: false
  end

  describe "Consumer DSL configuration" do
    test "resolves callback configuration from DSL" do
      config = TestConsumer.callback_config()
      
      assert is_map(config)
      assert config.enhanced_logging == true
      assert config.auto_create_users == false
    end

    test "resolves enabled callbacks from DSL" do
      enabled = TestConsumer.enabled_callbacks()
      
      assert is_list(enabled)
      
      # Core callbacks should always be enabled
      assert :ready in enabled
      assert :interaction_create in enabled
      
      # Message events should be enabled
      assert :message_create in enabled
      
      # Typing should be disabled
      refute :typing_start in enabled
    end

    test "callback_enabled? works correctly" do
      assert TestConsumer.callback_enabled?(:ready)
      assert TestConsumer.callback_enabled?(:message_create)
      refute TestConsumer.callback_enabled?(:typing_start)
    end
  end
end