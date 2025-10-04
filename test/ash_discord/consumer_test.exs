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
      copy(Nostrum.Api.ApplicationCommand)

      stub(Nostrum.Api.ApplicationCommand, :bulk_overwrite_guild_commands, fn _guild_id,
                                                                              _commands ->
        {:ok, []}
      end)

      :ok
    end

    test "has handle_event callback" do
      # All events now go through handle_event/1
      assert function_exported?(TestConsumer, :handle_event, 1)
    end

    test "interaction handling works" do
      interaction_data =
        interaction(%{
          data: %{name: "hello", options: []},
          member: member(%{user_id: user().id})
        })

      expect(Nostrum.Api.Interaction, :create_response, fn _interaction_id, _token, _response ->
        {:ok}
      end)

      ws_state = %Nostrum.Struct.WSState{}
      TestConsumer.handle_event({:INTERACTION_CREATE, interaction_data, ws_state})

      # Callback receives Payload, not Nostrum struct
      assert %AshDiscord.Consumer.Payloads.Interaction{id: interaction_id} = Process.get(:last_interaction)
      assert interaction_id == interaction_data.id
      assert {:ok, _response} = Process.get(:last_interaction_result)
    end

    test "application command routing works" do
      command_interaction =
        interaction(%{
          type: 2,
          data: %{name: "hello", options: []},
          member: %{user: user()}
        })

      expect(Nostrum.Api.Interaction, :create_response, fn _interaction_id, _token, _response ->
        {:ok}
      end)

      ws_state = %Nostrum.Struct.WSState{}
      TestConsumer.handle_event({:INTERACTION_CREATE, command_interaction, ws_state})

      # Callback receives Payload, not Nostrum struct
      assert %AshDiscord.Consumer.Payloads.Interaction{id: interaction_id} = Process.get(:last_interaction)
      assert interaction_id == command_interaction.id
    end

    test "from_discord actions work with consumer - guild" do
      guild_data = guild()

      ws_state = %Nostrum.Struct.WSState{}
      TestConsumer.handle_event({:GUILD_CREATE, guild_data, ws_state})

      guilds = TestApp.Discord.Guild.read!()
      assert length(guilds) == 1

      created_guild = hd(guilds)
      assert created_guild.discord_id == guild_data.id
      assert created_guild.name == guild_data.name
    end

    test "message creation works with consumer" do
      message_data = message()

      expect(Nostrum.Api.Channel, :get, fn _channel_id ->
        {:ok, channel()}
      end)

      expect(Nostrum.Api.Guild, :get, fn _guild_id ->
        {:ok, guild()}
      end)

      expect(Nostrum.Api.User, :get, fn _user_id ->
        {:ok, user()}
      end)

      ws_state = %Nostrum.Struct.WSState{}
      TestConsumer.handle_event({:MESSAGE_CREATE, message_data, ws_state})

      messages = TestApp.Discord.Message.read!()
      assert length(messages) == 1

      created_message = hd(messages)
      assert created_message.discord_id == message_data.id
      assert created_message.content == message_data.content
    end
  end
end
