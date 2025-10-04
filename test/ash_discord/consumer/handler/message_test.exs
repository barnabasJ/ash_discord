defmodule AshDiscord.Consumer.Handler.MessageTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord
  import Mimic

  alias AshDiscord.Consumer.Handler.Message
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  setup do
    copy(Nostrum.Api.Channel)
    copy(Nostrum.Api.Guild)
    copy(Nostrum.Api.User)
    :ok
  end

  describe "create/3" do
    test "creates message from Discord event" do
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

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      assert :ok = Message.create(message_data, %Nostrum.Struct.WSState{}, context)

      messages = TestApp.Discord.Message.read!()
      assert length(messages) == 1

      created_message = hd(messages)
      assert created_message.discord_id == message_data.id
      assert created_message.content == message_data.content
    end

    test "skips bot messages when store_bot_messages is false" do
      bot_user = user(%{bot: true})
      message_data = message(%{author: bot_user})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      assert :ok = Message.create(message_data, %Nostrum.Struct.WSState{}, context)

      messages = TestApp.Discord.Message.read!()
      assert length(messages) == 0
    end

    test "handles errors gracefully" do
      message_data = message()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      assert :ok = Message.create(message_data, %Nostrum.Struct.WSState{}, context)
    end
  end

  describe "update/3" do
    test "updates existing message" do
      message_data = message(%{content: "Updated content"})

      expect(Nostrum.Api.Channel, :get, fn _channel_id ->
        {:ok, channel()}
      end)

      expect(Nostrum.Api.Guild, :get, fn _guild_id ->
        {:ok, guild()}
      end)

      expect(Nostrum.Api.User, :get, fn _user_id ->
        {:ok, user()}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      # Create MessageUpdate payload
      {:ok, message_payload} = Payloads.Message.new(message_data)

      message_update = %Payloads.MessageUpdate{
        old_message: nil,
        updated_message: message_payload
      }

      assert :ok = Message.update(message_update, %Nostrum.Struct.WSState{}, context)

      messages = TestApp.Discord.Message.read!()
      assert length(messages) == 1

      updated = hd(messages)
      assert updated.discord_id == message_data.id
      assert updated.content == "Updated content"
    end
  end

  describe "delete/3" do
    test "deletes message by discord_id" do
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

      {:ok, _created} =
        TestApp.Discord.Message
        |> Ash.Changeset.for_create(:from_discord, %{
          data: message_data
        })
        |> Ash.create()

      messages_before = TestApp.Discord.Message.read!()
      assert length(messages_before) == 1

      delete_event =
        message_delete_event(%{
          id: message_data.id,
          channel_id: message_data.channel_id,
          guild_id: message_data.guild_id
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      assert :ok = Message.delete(delete_event, %Nostrum.Struct.WSState{}, context)

      messages_after = TestApp.Discord.Message.read!()
      assert length(messages_after) == 0
    end
  end

  describe "bulk/3" do
    test "bulk deletes multiple messages" do
      message1_data = message()
      message2_data = message()

      expect(Nostrum.Api.Channel, :get, 2, fn _channel_id ->
        {:ok, channel()}
      end)

      expect(Nostrum.Api.Guild, :get, 2, fn _guild_id ->
        {:ok, guild()}
      end)

      expect(Nostrum.Api.User, :get, 2, fn _user_id ->
        {:ok, user()}
      end)

      {:ok, _} =
        TestApp.Discord.Message
        |> Ash.Changeset.for_create(:from_discord, %{
          data: message1_data
        })
        |> Ash.create()

      {:ok, _} =
        TestApp.Discord.Message
        |> Ash.Changeset.for_create(:from_discord, %{
          data: message2_data
        })
        |> Ash.create()

      messages_before = TestApp.Discord.Message.read!()
      assert length(messages_before) == 2

      bulk_event =
        message_delete_bulk_event(%{
          ids: [message1_data.id, message2_data.id],
          channel_id: message1_data.channel_id,
          guild_id: message1_data.guild_id
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      assert :ok = Message.bulk(bulk_event, %Nostrum.Struct.WSState{}, context)

      messages_after = TestApp.Discord.Message.read!()
      assert length(messages_after) == 0
    end

    test "handles empty IDs list gracefully" do
      bulk_event = message_delete_bulk_event(%{ids: []})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      assert :ok = Message.bulk(bulk_event, %Nostrum.Struct.WSState{}, context)
    end
  end

  describe "ack/3" do
    test "acknowledges message without error" do
      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      assert :ok = Message.ack(%{}, %Nostrum.Struct.WSState{}, context)
    end
  end
end
