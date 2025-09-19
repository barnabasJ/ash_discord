defmodule AshDiscord.LoggerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias AshDiscord.Logger, as: AshLogger

  describe "log_interaction/4" do
    test "logs interaction with structured metadata" do
      interaction = %{
        id: "interaction_123",
        type: 2,
        user: %{id: "user_456"},
        guild_id: "guild_789",
        channel_id: "channel_012",
        data: %{name: "test_command"}
      }

      log = capture_log(fn ->
        AshLogger.log_interaction(:info, "Test interaction", interaction)
      end)

      assert String.contains?(log, "[AshDiscord.Interaction] Test interaction")
      assert String.contains?(log, "interaction_id=interaction_123")
      assert String.contains?(log, "command_name=test_command")
      assert String.contains?(log, "user_id=user_456")
      assert String.contains?(log, "guild_id=guild_789")
    end

    test "handles missing interaction fields gracefully" do
      interaction = %{id: "interaction_123", type: 1}

      log = capture_log(fn ->
        AshLogger.log_interaction(:debug, "Minimal interaction", interaction)
      end)

      assert String.contains?(log, "interaction_id=interaction_123")
      assert String.contains?(log, "command_name=unknown")
      assert String.contains?(log, "user_id=unknown")
    end

    test "includes additional metadata when provided" do
      interaction = %{id: "interaction_123", type: 2}
      metadata = %{custom_field: "custom_value", processing_time: 150}

      log = capture_log(fn ->
        AshLogger.log_interaction(:info, "Custom metadata", interaction, metadata)
      end)

      assert String.contains?(log, "custom_field=custom_value")
      assert String.contains?(log, "processing_time=150")
    end
  end

  describe "log_command_execution/5" do
    test "logs successful command execution with timing" do
      command = %{name: :test_command, resource: TestResource, action: :create}
      interaction = %{id: "interaction_123", user: %{id: "user_456"}}

      log = capture_log(fn ->
        AshLogger.log_command_execution(command, interaction, {:ok, "result"}, 250)
      end)

      assert String.contains?(log, "[AshDiscord.Command] Command test_command success in 250ms")
      assert String.contains?(log, "command=test_command")
      assert String.contains?(log, "resource=TestResource")
      assert String.contains?(log, "execution_time_ms=250")
      assert String.contains?(log, "status=success")
    end

    test "logs failed command execution" do
      command = %{name: :failing_command, resource: TestResource, action: :create}
      interaction = %{id: "interaction_123"}

      log = capture_log(fn ->
        AshLogger.log_command_execution(command, interaction, {:error, "validation failed"}, 100)
      end)

      assert String.contains?(log, "Command failing_command failed in 100ms")
      assert String.contains?(log, "status=failed")
    end

    test "logs slow commands separately" do
      command = %{name: :slow_command, resource: TestResource, action: :read}
      interaction = %{id: "interaction_123"}

      log = capture_log(fn ->
        AshLogger.log_command_execution(command, interaction, {:ok, "result"}, 1500)
      end)

      # Should log both normal execution and slow operation
      assert String.contains?(log, "Command slow_command success in 1500ms")
      assert String.contains?(log, "[AshDiscord.Performance] Slow command: slow_command")
    end
  end

  describe "log_ash_action/5" do
    test "logs successful Ash action" do
      log = capture_log(fn ->
        AshLogger.log_ash_action(:debug, :create, TestResource, :create_user, {:ok, %{}})
      end)

      assert String.contains?(log, "[AshDiscord.Ash] create TestResource.create_user succeeded")
      assert String.contains?(log, "action_type=create")
      assert String.contains?(log, "resource=TestResource")
      assert String.contains?(log, "action=create_user")
    end

    test "logs failed Ash action with error details" do
      error = %Ash.Error.Invalid{errors: []}

      log = capture_log(fn ->
        AshLogger.log_ash_action(:error, :create, TestResource, :create_user, {:error, error})
      end)

      assert String.contains?(log, "create TestResource.create_user failed")
      assert String.contains?(log, "error_type=validation")
    end
  end

  describe "log_discord_api_call/5" do
    test "logs successful Discord API call" do
      log = capture_log(fn ->
        AshLogger.log_discord_api_call("POST", "/interactions/response", {:ok, %{status: 200}})
      end)

      assert String.contains?(log, "[AshDiscord.API] Discord API POST /interactions/response succeeded")
      assert String.contains?(log, "discord_api_method=POST")
      assert String.contains?(log, "discord_api_endpoint=/interactions/response")
    end

    test "logs API call with retry information" do
      log = capture_log(fn ->
        AshLogger.log_discord_api_call("POST", "/commands", {:ok, %{status: 200}}, 3)
      end)

      assert String.contains?(log, "succeeded after 3 attempts")
      assert String.contains?(log, "attempt_number=3")
    end

    test "logs transient API failures as warnings" do
      log = capture_log(fn ->
        AshLogger.log_discord_api_call("GET", "/guilds", {:error, %{status: 429, message: "Rate limited"}})
      end)

      assert String.contains?(log, "[warning]")
      assert String.contains?(log, "failed (transient)")
      assert String.contains?(log, "http_status=429")
      assert String.contains?(log, "transient_error=true")
    end

    test "logs permanent API failures as errors" do
      log = capture_log(fn ->
        AshLogger.log_discord_api_call("DELETE", "/messages", {:error, %{status: 403, message: "Forbidden"}})
      end)

      assert String.contains?(log, "[error]")
      assert String.contains?(log, "transient_error=false")
    end
  end

  describe "log_consumer_event/4" do
    test "logs enabled callback processing" do
      log = capture_log(fn ->
        AshLogger.log_consumer_event(:MESSAGE_CREATE, true, :ok, %{message_id: "msg_123"})
      end)

      assert String.contains?(log, "[AshDiscord.Consumer] Event MESSAGE_CREATE processed successfully")
      assert String.contains?(log, "event_type=MESSAGE_CREATE")
      assert String.contains?(log, "callback_enabled=true")
      assert String.contains?(log, "message_id=msg_123")
    end

    test "logs disabled callback skipping" do
      log = capture_log(fn ->
        AshLogger.log_consumer_event(:TYPING_START, false)
      end)

      assert String.contains?(log, "Event TYPING_START skipped (callback disabled)")
    end

    test "logs callback processing failures" do
      log = capture_log(fn ->
        AshLogger.log_consumer_event(:GUILD_CREATE, true, {:error, "database error"})
      end)

      assert String.contains?(log, "[error]")
      assert String.contains?(log, "Event GUILD_CREATE processing failed")
    end
  end

  describe "log_configuration_resolution/4" do
    test "logs configuration details" do
      enabled_callbacks = [:message_create, :guild_create, :interaction_create]
      config_options = %{enhanced_logging: true, performance_optimized: false}

      log = capture_log(fn ->
        AshLogger.log_configuration_resolution(:production, enabled_callbacks, config_options)
      end)

      assert String.contains?(log, "[AshDiscord.Config] Configuration resolved: production profile with 3 callbacks enabled")
      assert String.contains?(log, "callback_profile=production")
      assert String.contains?(log, "enabled_callback_count=3")
    end
  end

  describe "log_slow_operation/4" do
    test "logs slow operations with appropriate severity" do
      # Test different severity levels based on duration
      test_cases = [
        {500, :debug},
        {2000, :info},
        {7000, :warning},
        {12000, :error}
      ]

      for {duration, expected_level} <- test_cases do
        log = capture_log(fn ->
          AshLogger.log_slow_operation("database_query", "find_user", duration)
        end)

        assert String.contains?(log, "[#{expected_level}]")
        assert String.contains?(log, "[AshDiscord.Performance] Slow database_query: find_user (#{duration}ms)")
        assert String.contains?(log, "slow_operation=true")
      end
    end
  end

  describe "log_command_registration/3" do
    test "logs successful command registration" do
      commands = [
        %{name: :chat},
        %{name: :history}
      ]

      log = capture_log(fn ->
        AshLogger.log_command_registration(commands, {:ok, []})
      end)

      assert String.contains?(log, "[AshDiscord.Registration] Successfully registered 2 Discord commands")
      assert String.contains?(log, "command_count=2")
      assert String.contains?(log, "command_names=[:chat, :history]")
    end

    test "logs failed command registration" do
      commands = [%{name: :test}]

      log = capture_log(fn ->
        AshLogger.log_command_registration(commands, {:error, "Invalid token"})
      end)

      assert String.contains?(log, "[error]")
      assert String.contains?(log, "Failed to register Discord commands")
    end
  end

  describe "timer functionality" do
    test "start_timer and end_timer measure duration" do
      timer = AshLogger.start_timer("test_operation")
      
      Process.sleep(50)  # Small delay
      
      log = capture_log(fn ->
        duration = AshLogger.end_timer(timer, 25)  # Low threshold to trigger logging
        assert duration >= 50
      end)

      assert String.contains?(log, "Slow timed_operation: test_operation")
    end

    test "end_timer does not log fast operations" do
      timer = AshLogger.start_timer("fast_operation")
      
      log = capture_log(fn ->
        duration = AshLogger.end_timer(timer, 1000)  # High threshold
        assert duration >= 0
      end)

      # Should not log anything for fast operations
      refute String.contains?(log, "Slow timed_operation")
    end
  end
end