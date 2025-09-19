defmodule AshDiscord.ConsumerTest do
  use TestApp.DataCase, async: false

  alias TestApp.TestConsumer

  describe "Consumer using macro" do
    test "generates callback functions" do
      callbacks_arity_1 = [
        :handle_message_create,
        :handle_message_update,
        :handle_message_delete,
        :handle_message_delete_bulk,
        :handle_message_reaction_add,
        :handle_message_reaction_remove,
        :handle_message_reaction_remove_all,
        :handle_guild_create,
        :handle_guild_update,
        :handle_guild_delete,
        :handle_guild_role_create,
        :handle_guild_role_update,
        :handle_guild_role_delete,
        :handle_channel_create,
        :handle_channel_update,
        :handle_channel_delete,
        :handle_ready,
        :handle_interaction_create,
        :handle_application_command,
        :handle_unknown_event
      ]

      callbacks_arity_2 = [
        :handle_guild_member_add,
        :handle_guild_member_update,
        :handle_guild_member_remove
      ]

      for callback <- callbacks_arity_1 do
        assert function_exported?(TestConsumer, callback, 1)
      end

      for callback <- callbacks_arity_2 do
        assert function_exported?(TestConsumer, callback, 2)
      end
    end

    test "overridden callbacks work correctly" do
      # Test message create override - use proper Nostrum struct
      message = %Nostrum.Struct.Message{
        id: 123_456_789,
        content: "test message",
        channel_id: 987_654_321,
        author: %Nostrum.Struct.User{
          id: 111_222_333,
          username: "testuser",
          discriminator: "0001",
          avatar: nil,
          bot: false
        },
        guild_id: 444_555_666,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      # This should call our override
      result = TestConsumer.handle_message_create(message)
      assert result == :ok
    end

    test "interaction handling works" do
      interaction = %{
        # APPLICATION_COMMAND
        id: "interaction_123456789",
        type: 2,
        data: %{
          name: "hello",
          options: []
        },
        guild_id: 123_456_789,
        channel_id: 987_654_321,
        member: %{
          user: %{id: 111_222_333}
        }
      }

      TestConsumer.handle_interaction_create(interaction)

      # Verify interaction was stored
      assert Process.get(:last_interaction) == interaction
      assert Process.get(:last_interaction_result) == :ok
    end

    test "application command routing works" do
      command_interaction = %{
        type: 2,
        data: %{
          name: "hello",
          options: []
        },
        guild_id: 123_456_789,
        channel_id: 987_654_321,
        member: %{
          user: %{id: 111_222_333}
        }
      }

      TestConsumer.handle_application_command(command_interaction)

      # Verify command was processed
      assert Process.get(:last_command) == command_interaction
      assert Process.get(:last_command_result) == :ok
    end
  end

  describe "Resource integration" do
    test "from_discord actions work with consumer" do
      # Use proper Nostrum guild struct
      guild = %Nostrum.Struct.Guild{
        id: 123_456_789,
        name: "Test Guild",
        icon: nil,
        description: nil,
        owner_id: 987_654_321,
        member_count: 10
      }

      TestConsumer.handle_guild_create(guild)

      # Verify guild was created
      guilds = TestApp.Discord.Guild.read!()
      assert length(guilds) == 1

      guild = hd(guilds)
      assert guild.discord_id == 123_456_789
      # From our mock
      assert guild.name == "Test Guild 123456789"
    end

    test "message creation works with consumer" do
      # Use proper Nostrum message struct
      message = %Nostrum.Struct.Message{
        id: 987_654_321,
        content: "Hello world",
        channel_id: 123_456_789,
        author: %Nostrum.Struct.User{
          id: 111_222_333,
          username: "testuser",
          discriminator: "0001",
          avatar: nil,
          bot: false
        },
        guild_id: 444_555_666,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      TestConsumer.handle_message_create(message)

      # Verify message was created
      messages = TestApp.Discord.Message.read!()
      assert length(messages) == 1

      message = hd(messages)
      assert message.discord_id == 987_654_321
      # From our mock
      assert message.content == "Test message 987654321"
    end
  end
end
