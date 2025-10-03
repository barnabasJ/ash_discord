defmodule AshDiscord.ConsumerTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord
  import Mimic

  alias TestApp.TestConsumer

  describe "Consumer using macro" do
    setup do
      copy(Nostrum.Api.Interaction)
      copy(Nostrum.Api.Channel)
      copy(Nostrum.Api.Guild)
      copy(Nostrum.Api.User)
      :ok
    end

    test "has handle_event callback" do
      # All events now go through handle_event/1
      assert function_exported?(TestConsumer, :handle_event, 1)
    end

    test "interaction handling works" do
      interaction =
        interaction(%{
          data: %{name: "hello", options: []},
          member: member(%{user_id: user().id})
        })

      # Mock the interaction response to avoid rate limiter issues
      expect(Nostrum.Api.Interaction, :create_response, fn _interaction_id, _token, _response ->
        {:ok, %{}}
      end)

      ws_state = %Nostrum.Struct.WSState{}
      TestConsumer.handle_event({:INTERACTION_CREATE, interaction, ws_state})

      # Verify interaction was stored
      assert Process.get(:last_interaction) == interaction
      assert Process.get(:last_interaction_result) == {:ok, %{}}
    end

    test "application command routing works" do
      command_interaction =
        interaction(%{
          # Application command
          type: 2,
          data: %{name: "hello", options: []},
          member: %{user: user()}
        })

      # Mock the interaction response to avoid rate limiter issues
      expect(Nostrum.Api.Interaction, :create_response, fn _interaction_id, _token, _response ->
        {:ok, %{}}
      end)

      ws_state = %Nostrum.Struct.WSState{}
      TestConsumer.handle_event({:INTERACTION_CREATE, command_interaction, ws_state})

      # Verify interaction was stored
      assert Process.get(:last_interaction) == command_interaction
    end
  end

  describe "Resource integration" do
    setup do
      copy(Nostrum.Api.ApplicationCommand)
      copy(Nostrum.Api.Channel)
      copy(Nostrum.Api.Guild)
      copy(Nostrum.Api.User)

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

      ws_state = %Nostrum.Struct.WSState{}
      TestConsumer.handle_event({:GUILD_CREATE, guild, ws_state})

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

      # Mock channel API call for relationship management
      expect(Nostrum.Api.Channel, :get, fn channel_id ->
        if channel_id == message_data.channel_id do
          {:ok, channel(%{id: message_data.channel_id, name: "test-channel", type: 0})}
        else
          {:error, :not_found}
        end
      end)

      # Mock guild API call for relationship management
      expect(Nostrum.Api.Guild, :get, fn guild_id ->
        if guild_id == message_data.guild_id do
          {:ok, guild(%{id: message_data.guild_id, name: "Test Guild"})}
        else
          {:error, :not_found}
        end
      end)

      # Mock user API call for relationship management
      expect(Nostrum.Api.User, :get, fn user_id ->
        if user_id == message_data.author.id do
          {:ok, user(%{id: message_data.author.id, username: message_data.author.username})}
        else
          {:error, :not_found}
        end
      end)

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

      ws_state = %Nostrum.Struct.WSState{}
      TestConsumer.handle_event({:MESSAGE_CREATE, message, ws_state})

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
