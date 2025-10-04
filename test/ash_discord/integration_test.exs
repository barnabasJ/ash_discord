defmodule AshDiscord.IntegrationTest do
  use TestApp.DataCase

  import AshDiscord.Test.Generators.Discord
  import Mimic

  setup :verify_on_exit!

  setup do
    copy(Nostrum.Api.Interaction)
    copy(Nostrum.Api.User)
    copy(Nostrum.Api.Guild)
    copy(Nostrum.Api.Channel)

    :ok
  end

  defmodule IntegrationTestConsumer do
    use AshDiscord.Consumer

    ash_discord_consumer do
      domains([TestApp.Discord])
    end

    @impl AshDiscord.Consumer
    def handle_interaction_create(interaction, _ws_state, _context) do
      # Override to test integration
      command = find_command(String.to_atom(interaction.data.name))

      case AshDiscord.InteractionRouter.route_interaction(interaction, command,
             consumer: __MODULE__
           ) do
        {:ok, response} ->
          send(self(), {:interaction_response, response})
          :ok

        {:error, reason} ->
          send(self(), {:interaction_error, reason})
          :ok
      end
    end

    @impl AshDiscord.Consumer
    def handle_message_create(message, _ws_state, _context) do
      # Create message using from_discord action
      case TestApp.Discord.Message.from_discord(%{data: message}) do
        {:ok, created_message} ->
          send(self(), {:message_created, created_message})
          :ok

        {:error, reason} ->
          send(self(), {:message_error, reason})
          :ok
      end
    end
  end

  describe "end-to-end integration" do
    test "complete slash command workflow" do
      interaction =
        interaction(%{
          data: %{name: "ping", options: []},
          user: user(%{username: "testuser"})
        })

      # Mock the interaction response to avoid rate limiter issues
      expect(Nostrum.Api.Interaction, :create_response, fn _interaction_id, _token, _response ->
        {:ok}
      end)

      # Process the interaction
      ws_state = %Nostrum.Struct.WSState{}

      result =
        IntegrationTestConsumer.handle_interaction_create(
          interaction,
          ws_state,
          %AshDiscord.Context{}
        )

      assert result == :ok

      # Should receive response
      assert_receive {:interaction_response, response}, 1000
      assert is_map(response)
    end

    test "consumer processes message events with from_discord actions" do
      # Pre-create entities to avoid relationship management issues
      guild_id = generate_snowflake()
      channel_id = generate_snowflake()
      user_id = generate_snowflake()

      {:ok, _guild} =
        TestApp.Discord.Guild.create(%{
          discord_id: guild_id,
          name: "Test Guild"
        })

      {:ok, _channel} =
        TestApp.Discord.Channel.create(%{
          discord_id: channel_id,
          name: "test-channel",
          type: 0,
          guild_id: guild_id
        })

      {:ok, _user} =
        TestApp.Discord.User.create(%{
          discord_id: user_id,
          discord_username: "testuser"
        })

      message_data =
        message(%{
          content: "Test message content",
          channel_id: channel_id,
          guild_id: guild_id,
          author: user(%{id: user_id})
        })

      ws_state = %Nostrum.Struct.WSState{}

      result =
        IntegrationTestConsumer.handle_message_create(
          message_data,
          ws_state,
          %AshDiscord.Context{}
        )

      assert result == :ok

      # Should receive message creation confirmation
      assert_receive {:message_created, created_message}, 1000
      assert created_message.discord_id == message_data.id
      assert created_message.content == message_data.content
    end

    test "consumer command collection works correctly" do
      commands = AshDiscord.Consumer.collect_commands(IntegrationTestConsumer.domains())

      assert is_list(commands)
      assert length(commands) > 0

      # Should include commands from TestApp.Discord domain
      ping_command = Enum.find(commands, &(&1.name == :ping))
      assert ping_command != nil
      assert ping_command.description == "Test ping command"
    end

    test "discord command conversion works" do
      commands = AshDiscord.Consumer.collect_commands(IntegrationTestConsumer.domains())
      ping_command = Enum.find(commands, &(&1.name == :ping))

      discord_command = AshDiscord.Consumer.to_discord_command(ping_command)

      assert discord_command.name == "ping"
      assert discord_command.description == "Test ping command"
      # CHAT_INPUT
      assert discord_command.type == 1
      assert discord_command.options == []
    end

    test "command with options converts correctly" do
      commands = AshDiscord.Consumer.collect_commands(IntegrationTestConsumer.domains())
      echo_command = Enum.find(commands, &(&1.name == :echo))

      discord_command = AshDiscord.Consumer.to_discord_command(echo_command)

      assert discord_command.name == "echo"
      assert discord_command.description == "Echo back a message"
      assert length(discord_command.options) == 1

      message_option = List.first(discord_command.options)
      assert message_option.name == "message"
      # STRING
      assert message_option.type == 3
      assert message_option.required == true
    end
  end

  describe "error handling" do
    @tag :focus
    test "handles invalid interaction gracefully" do
      invalid_interaction =
        interaction(%{
          data: %{name: "nonexistent_command", options: []}
        })

      # Mock the interaction response to avoid rate limiter issues
      expect(Nostrum.Api.Interaction, :create_response, fn _interaction_id, _token, _response ->
        {:ok}
      end)

      ws_state = %Nostrum.Struct.WSState{}

      {result, log} =
        ExUnit.CaptureLog.with_log(fn ->
          IntegrationTestConsumer.handle_interaction_create(
            invalid_interaction,
            ws_state,
            %AshDiscord.Context{}
          )
        end)

      assert log =~ "command is nil"
      assert result == :ok

      # Should receive error notification
      assert_receive {:interaction_error, _reason}, 1000
    end

    test "handles message creation errors" do
      # Create a proper Nostrum struct but with missing required relationships
      # This will cause a validation error when trying to create the message
      invalid_message_data =
        message(%{
          id: generate_snowflake(),
          content: "Test message",
          channel_id: 999_999_999,
          # Non-existent channel/guild IDs will cause relationship errors
          guild_id: 888_888_888,
          author: user(%{id: 777_777_777})
        })

      ws_state = %Nostrum.Struct.WSState{}

      result =
        IntegrationTestConsumer.handle_message_create(
          invalid_message_data,
          ws_state,
          %AshDiscord.Context{}
        )

      assert result == :ok

      # Should receive error notification
      assert_receive {:message_error, _reason}, 1000
    end
  end

  describe "consumer macro behavior" do
    test "consumer has all required callback functions" do
      # Test that handle_event callback was generated
      # All events now go through handle_event/1
      assert function_exported?(IntegrationTestConsumer, :handle_event, 1),
             "Callback handle_event/1 not exported"
    end

    test "consumer has correct domains configured" do
      assert IntegrationTestConsumer.domains() == [TestApp.Discord]
    end

    test "consumer find_command works with configured domains" do
      command = IntegrationTestConsumer.find_command(:ping)

      assert command != nil
      assert command.name == :ping
    end
  end
end
