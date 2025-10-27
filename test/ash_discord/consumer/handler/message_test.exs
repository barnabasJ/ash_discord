defmodule AshDiscord.Consumer.Handler.MessageTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators
  use Mimic

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
    @tag :fixed
    test "creates message from Discord event" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      author_data = user()

      message_data =
        message(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          author: author_data
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      message_payload = Payloads.Message.new!(message_data)

      assert :ok = Message.create(message_payload, %Nostrum.Struct.WSState{}, context)

      [created_message] =
        TestApp.Discord.Message
        |> Ash.Query.load([:guild, :author, :channel])
        |> Ash.read!(authorize?: false)

      assert created_message.discord_id == message_data.id
      assert created_message.content == message_data.content
      assert created_message.guild.discord_id == guild_data.id
      assert created_message.author.discord_id == author_data.id
      assert created_message.channel.discord_id == channel_data.id
    end

    @tag :fixed
    test "skips bot messages when store_bot_messages is false" do
      bot_user = user(%{bot: true})
      message_data = message(%{author: bot_user})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      message_payload = Payloads.Message.new!(message_data)

      assert :ok = Message.create(message_payload, %Nostrum.Struct.WSState{}, context)

      assert [] = TestApp.Discord.Message.read!(authorize?: false)
    end

    @tag :fixed
    test "handles errors gracefully" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      author_data = user()

      message_data =
        message(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          author: author_data
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      message_payload = Payloads.Message.new!(message_data)

      assert :ok = Message.create(message_payload, %Nostrum.Struct.WSState{}, context)
    end
  end

  describe "update/3" do
    @tag :fixed
    test "updates existing message" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      author_data = user()

      message_data =
        message(%{
          content: "Updated content",
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          author: author_data
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      message_payload = Payloads.Message.new!(message_data)

      message_update = %Payloads.MessageUpdate{
        old_message: nil,
        updated_message: message_payload
      }

      assert :ok = Message.update(message_update, %Nostrum.Struct.WSState{}, context)

      [updated] =
        TestApp.Discord.Message
        |> Ash.Query.load([:guild, :author, :channel])
        |> Ash.read!(authorize?: false)

      assert updated.discord_id == message_data.id
      assert updated.content == "Updated content"
      assert updated.guild.discord_id == guild_data.id
      assert updated.author.discord_id == author_data.id
      assert updated.channel.discord_id == channel_data.id
    end
  end

  describe "delete/3" do
    @tag :fixed
    test "deletes message by discord_id" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      author_data = user()

      message_data =
        message(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          author: author_data
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      assert [_] = TestApp.Discord.Message.read!(authorize?: false)

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

      assert [] = TestApp.Discord.Message.read!(authorize?: false)
    end
  end

  describe "bulk/3" do
    @tag :fixed
    test "bulk deletes multiple messages" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      author_data = user()

      message1_data =
        message(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          author: author_data
        })

      message2_data =
        message(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          author: author_data
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message1_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message2_data}, authorize?: false)

      assert [_, _] = TestApp.Discord.Message.read!(authorize?: false)

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

      assert :ok = Message.delete_bulk(bulk_event, %Nostrum.Struct.WSState{}, context)

      assert [] = TestApp.Discord.Message.read!(authorize?: false)
    end

    @tag :fixed
    test "handles empty IDs list gracefully" do
      bulk_event = message_delete_bulk_event(%{ids: []})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Message,
        guild: nil,
        user: nil
      }

      assert :ok = Message.delete_bulk(bulk_event, %Nostrum.Struct.WSState{}, context)
    end
  end

  describe "ack/3" do
    @tag :fixed
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
