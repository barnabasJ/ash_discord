defmodule AshDiscord.ConsumerTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord
  import Mimic

  alias TestApp.TestConsumer

  describe "Consumer using macro" do
    setup do
      copy(Nostrum.Api.Interaction)
      :ok
    end

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
      test_user = user(%{username: "testuser", discriminator: "0001"})

      message = %Nostrum.Struct.Message{
        id: generate_snowflake(),
        content: "test message",
        channel_id: generate_snowflake(),
        author: %Nostrum.Struct.User{
          id: test_user.id,
          username: test_user.username,
          discriminator: test_user.discriminator,
          avatar: test_user.avatar,
          bot: test_user.bot
        },
        guild_id: generate_snowflake(),
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      # This should call our override
      result = TestConsumer.handle_message_create(message)
      assert result == :ok
    end

    test "interaction handling works" do
      interaction =
        interaction(%{
          data: %{name: "hello", options: []},
          member: %{user: user()}
        })

      TestConsumer.handle_interaction_create(interaction)

      # Verify interaction was stored
      assert Process.get(:last_interaction) == interaction
      assert Process.get(:last_interaction_result) == :ok
    end

    test "application command routing works" do
      command_interaction =
        interaction(%{
          data: %{name: "hello", options: []},
          member: %{user: user()}
        })

      # Mock the interaction response to avoid rate limiter issues
      expect(Nostrum.Api.Interaction, :create_response, fn _interaction_id, _token, _response ->
        {:ok, %{}}
      end)

      TestConsumer.handle_application_command(command_interaction)

      # Verify command was processed
      assert Process.get(:last_command) == command_interaction
      assert Process.get(:last_command_result) == {:ok, %{}}
    end
  end

  describe "Resource integration" do
    setup do
      copy(Nostrum.Api.ApplicationCommand)

      stub(Nostrum.Api.ApplicationCommand, :bulk_overwrite_guild_commands, fn _guild_id,
                                                                              _commands ->
        {:ok, []}
      end)

      :ok
    end

    test "from_discord actions work with consumer" do
      # Use proper Nostrum guild struct
      guild_data = guild(%{name: "Test Guild", member_count: 10})

      guild = %Nostrum.Struct.Guild{
        id: guild_data.id,
        name: guild_data.name,
        icon: guild_data.icon,
        description: guild_data.description,
        owner_id: guild_data.owner_id,
        member_count: guild_data.member_count
      }

      TestConsumer.handle_guild_create(guild)

      # Verify guild was created
      guilds = TestApp.Discord.Guild.read!()
      assert length(guilds) == 1

      created_guild = hd(guilds)
      assert created_guild.discord_id == guild_data.id
      # Should match the Discord struct name directly
      assert created_guild.name == guild_data.name
    end

    test "message creation works with consumer" do
      # Use proper Nostrum message struct
      message_data = message(%{content: "Hello world"})

      message = %Nostrum.Struct.Message{
        id: message_data.id,
        content: message_data.content,
        channel_id: message_data.channel_id,
        author: %Nostrum.Struct.User{
          id: message_data.author.id,
          username: message_data.author.username,
          discriminator: message_data.author.discriminator,
          avatar: message_data.author.avatar,
          bot: message_data.author.bot
        },
        guild_id: message_data.guild_id,
        timestamp: message_data.timestamp
      }

      TestConsumer.handle_message_create(message)

      # Verify message was created
      messages = TestApp.Discord.Message.read!()
      assert length(messages) == 1

      created_message = hd(messages)
      assert created_message.discord_id == message_data.id
      # Should use actual content since we're now passing it
      assert created_message.content == message_data.content
    end
  end
end
