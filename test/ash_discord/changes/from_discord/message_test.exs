defmodule AshDiscord.Changes.FromDiscord.MessageTest do
  @moduledoc """
  Comprehensive tests for Message entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators

  describe "struct-first pattern" do
    @tag :fixed
    test "creates message from discord struct with all attributes" do
      channel_id = 555_666_777
      guild_id = 111_222_333
      user_id = 987_654_321

      expect(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0, guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      expect(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      message_struct =
        message(%{
          id: 123_456_789,
          content: "Hello, Discord!",
          author: user(%{id: user_id, username: "test_user"}),
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: "2023-01-15T10:30:00Z",
          edited_timestamp: nil,
          tts: false,
          mention_everyone: false,
          pinned: false
        })

      created_message =
        TestApp.Discord.message_from_discord!(%{data: message_struct},
          load: [:guild, :author, :channel]
        )

      assert created_message.discord_id == message_struct.id
      assert created_message.content == message_struct.content
      assert created_message.timestamp == ~U[2023-01-15 10:30:00Z]
      assert created_message.edited_timestamp == nil
      assert created_message.tts == false
      assert created_message.mention_everyone == false
      assert created_message.pinned == false
      assert created_message.author.discord_id == user_id
      assert created_message.author.discord_username == "test_user_#{user_id}"
      assert created_message.channel.discord_id == channel_id
      assert created_message.channel.name == "test-channel"
      assert created_message.guild.discord_id == guild_id
      assert created_message.guild.name == "Test Guild"
    end

    @tag :fixed
    test "handles edited message" do
      channel_id = 777_888_999
      guild_id = 555_666_777
      user_id = 123_456_789

      expect(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0, guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      expect(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      message_struct =
        message(%{
          id: 987_654_321,
          content: "This message was edited",
          author: user(%{id: user_id, username: "editor"}),
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: "2023-02-01T12:00:00Z",
          edited_timestamp: "2023-02-01T12:05:00Z",
          tts: false,
          mention_everyone: false,
          pinned: false
        })

      created_message =
        TestApp.Discord.message_from_discord!(%{data: message_struct},
          load: [:guild, :author, :channel]
        )

      assert created_message.discord_id == message_struct.id
      assert created_message.content == message_struct.content
      assert created_message.timestamp == ~U[2023-02-01 12:00:00Z]
      assert created_message.edited_timestamp == ~U[2023-02-01 12:05:00Z]
      assert created_message.author.discord_id == user_id
      assert created_message.author.discord_username == "test_user_#{user_id}"
      assert created_message.channel.discord_id == channel_id
      assert created_message.channel.name == "test-channel"
      assert created_message.guild.discord_id == guild_id
      assert created_message.guild.name == "Test Guild"
    end

    @tag :fixed
    test "handles TTS message" do
      channel_id = 777_888_999
      guild_id = 333_444_555
      user_id = 444_555_666

      expect(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0, guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      expect(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      message_struct =
        message(%{
          id: 111_222_333,
          content: "This is a text-to-speech message",
          author: user(%{id: user_id, username: "tts_user"}),
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: "2023-03-10T15:30:00Z",
          tts: true,
          mention_everyone: false,
          pinned: false
        })

      created_message =
        TestApp.Discord.message_from_discord!(%{data: message_struct},
          load: [:guild, :author, :channel]
        )

      assert created_message.discord_id == message_struct.id
      assert created_message.tts == true
      assert created_message.author.discord_id == user_id
      assert created_message.author.discord_username == "test_user_#{user_id}"
      assert created_message.channel.discord_id == channel_id
      assert created_message.channel.name == "test-channel"
      assert created_message.guild.discord_id == guild_id
      assert created_message.guild.name == "Test Guild"
    end

    @tag :fixed
    test "handles message with @everyone mention" do
      channel_id = 999_111_222
      guild_id = 777_888_999
      user_id = 666_777_888

      expect(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0, guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      expect(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      message_struct =
        message(%{
          id: 333_444_555,
          content: "@everyone Important announcement!",
          author: user(%{id: user_id, username: "announcer"}),
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: "2023-04-05T09:00:00Z",
          tts: false,
          mention_everyone: true,
          pinned: false
        })

      created_message =
        TestApp.Discord.message_from_discord!(%{data: message_struct},
          load: [:guild, :author, :channel]
        )

      assert created_message.discord_id == message_struct.id
      assert created_message.mention_everyone == true
      assert created_message.author.discord_id == user_id
      assert created_message.author.discord_username == "test_user_#{user_id}"
      assert created_message.channel.discord_id == channel_id
      assert created_message.channel.name == "test-channel"
      assert created_message.guild.discord_id == guild_id
      assert created_message.guild.name == "Test Guild"
    end

    @tag :fixed
    test "handles pinned message" do
      channel_id = 222_333_444
      guild_id = 111_222_333
      user_id = 888_999_111

      expect(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0, guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      expect(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      message_struct =
        message(%{
          id: 555_666_777,
          content: "This message is pinned",
          author: user(%{id: user_id, username: "pinner"}),
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: "2023-05-12T14:20:00Z",
          tts: false,
          mention_everyone: false,
          pinned: true
        })

      created_message =
        TestApp.Discord.message_from_discord!(%{data: message_struct},
          load: [:guild, :author, :channel]
        )

      assert created_message.discord_id == message_struct.id
      assert created_message.pinned == true
      assert created_message.author.discord_id == user_id
      assert created_message.author.discord_username == "test_user_#{user_id}"
      assert created_message.channel.discord_id == channel_id
      assert created_message.channel.name == "test-channel"
      assert created_message.guild.discord_id == guild_id
      assert created_message.guild.name == "Test Guild"
    end

    @tag :fixed
    test "handles nil content" do
      channel_id = 444_555_666
      guild_id = 999_888_777
      user_id = 111_222_333

      expect(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0, guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      expect(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      message_struct =
        message(%{
          id: 777_888_999,
          content: nil,
          author: user(%{id: user_id, username: "empty_user"}),
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: "2023-06-01T18:45:00Z",
          tts: false,
          mention_everyone: false,
          pinned: false
        })

      created_message =
        TestApp.Discord.message_from_discord!(%{data: message_struct},
          load: [:guild, :author, :channel]
        )

      assert created_message.discord_id == message_struct.id
      assert created_message.content == nil
      assert created_message.author.discord_id == user_id
      assert created_message.author.discord_username == "test_user_#{user_id}"
      assert created_message.channel.discord_id == channel_id
      assert created_message.channel.name == "test-channel"
      assert created_message.guild.discord_id == guild_id
      assert created_message.guild.name == "Test Guild"
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches message from API when data not provided" do
      channel_id = 555_666_777
      message_id = 999_888_777
      guild_id = 111_222_333
      user_id = 123_456_789

      expect(Nostrum.Api.Message, :get, fn ch_id, msg_id ->
        {:ok,
         message(%{
           id: msg_id,
           channel_id: ch_id,
           guild_id: guild_id,
           content: "API fetched message",
           author: user(%{id: user_id}),
           timestamp: "2023-06-15T10:00:00.000000Z",
           tts: false,
           mention_everyone: false,
           pinned: false
         })}
      end)

      expect(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0, guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "test-guild"})}
      end)

      expect(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      result =
        TestApp.Discord.message_from_discord(%{
          identity: %{channel_id: channel_id, message_id: message_id}
        })

      assert {:ok, created_message} = result
      assert created_message.discord_id == message_id
      assert created_message.content == "API fetched message"
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing message instead of creating duplicate" do
      channel_id = 111_222_333
      guild_id = 222_333_444
      user_id = 123_456_789

      expect(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0, guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      expect(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      discord_id = 555_666_777

      initial_struct =
        message(%{
          id: discord_id,
          content: "Original content",
          author: user(%{id: user_id, username: "author"}),
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: "2023-01-01T00:00:00Z",
          edited_timestamp: nil,
          pinned: false
        })

      {:ok, original_message} =
        TestApp.Discord.message_from_discord(%{data: initial_struct},
          load: [:guild, :author, :channel]
        )

      updated_struct =
        message(%{
          id: discord_id,
          content: "Edited content",
          author: user(%{id: user_id, username: "author"}),
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: "2023-01-01T00:00:00Z",
          edited_timestamp: "2023-01-01T00:05:00Z",
          pinned: true
        })

      {:ok, updated_message} =
        TestApp.Discord.message_from_discord(%{data: updated_struct},
          load: [:guild, :author, :channel]
        )

      assert updated_message.id == original_message.id
      assert updated_message.discord_id == original_message.discord_id
      assert updated_message.content == "Edited content"
      assert updated_message.edited_timestamp == ~U[2023-01-01 00:05:00Z]
      assert updated_message.pinned == true
      assert original_message.author.discord_id == user_id
      assert original_message.channel.discord_id == channel_id
      assert original_message.guild.discord_id == guild_id
      assert updated_message.author.discord_id == user_id
      assert updated_message.author.discord_username == "test_user_#{user_id}"
      assert updated_message.channel.discord_id == channel_id
      assert updated_message.channel.name == "test-channel"
      assert updated_message.guild.discord_id == guild_id
      assert updated_message.guild.name == "Test Guild"
    end

    @tag :fixed
    test "upsert works with pin status changes" do
      channel_id = 777_888_999
      guild_id = 555_666_777
      user_id = 987_654_321

      expect(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0, guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      expect(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      discord_id = 333_444_555

      initial_struct =
        message(%{
          id: discord_id,
          content: "Important message",
          author: user(%{id: user_id, username: "important_user"}),
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: "2023-07-01T10:00:00Z",
          pinned: false
        })

      {:ok, original_message} =
        TestApp.Discord.message_from_discord(%{data: initial_struct},
          load: [:guild, :author, :channel]
        )

      updated_struct =
        message(%{
          id: discord_id,
          content: "Important message",
          author: user(%{id: user_id, username: "important_user"}),
          channel_id: channel_id,
          guild_id: guild_id,
          timestamp: "2023-07-01T10:00:00Z",
          pinned: true
        })

      {:ok, updated_message} =
        TestApp.Discord.message_from_discord(%{data: updated_struct},
          load: [:guild, :author, :channel]
        )

      assert updated_message.id == original_message.id
      assert updated_message.discord_id == discord_id
      assert updated_message.pinned == true
      assert original_message.author.discord_id == user_id
      assert original_message.channel.discord_id == channel_id
      assert original_message.guild.discord_id == guild_id
      assert updated_message.author.discord_id == user_id
      assert updated_message.author.discord_username == "test_user_#{user_id}"
      assert updated_message.channel.discord_id == channel_id
      assert updated_message.channel.name == "test-channel"
      assert updated_message.guild.discord_id == guild_id
      assert updated_message.guild.name == "Test Guild"
    end
  end
end
