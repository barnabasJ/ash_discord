defmodule AshDiscord.Changes.FromDiscord.MessageTest do
  @moduledoc """
  Comprehensive tests for Message entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates message from discord struct with all attributes" do
      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user"})}
      end)

      message_struct =
        message(%{
          id: 123_456_789,
          content: "Hello, Discord!",
          author: user(%{id: 987_654_321, username: "test_user"}),
          channel_id: 555_666_777,
          guild_id: 111_222_333,
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
      assert created_message.author.discord_id == 987_654_321
      assert created_message.channel.discord_id == 555_666_777
      assert created_message.guild.discord_id == 111_222_333
      assert created_message.timestamp == ~U[2023-01-15 10:30:00Z]
      assert created_message.edited_timestamp == nil
      assert created_message.tts == false
      assert created_message.mention_everyone == false
      assert created_message.pinned == false
    end

    @tag :fixed
    test "handles edited message" do
      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "editor"})}
      end)

      message_struct =
        message(%{
          id: 987_654_321,
          content: "This message was edited",
          author: user(%{id: 123_456_789, username: "editor"}),
          channel_id: 777_888_999,
          guild_id: 555_666_777,
          timestamp: "2023-02-01T12:00:00Z",
          edited_timestamp: "2023-02-01T12:05:00Z",
          tts: false,
          mention_everyone: false,
          pinned: false
        })

      created_message = TestApp.Discord.message_from_discord!(%{data: message_struct})

      assert created_message.discord_id == message_struct.id
      assert created_message.content == message_struct.content
      assert created_message.timestamp == ~U[2023-02-01 12:00:00Z]
      assert created_message.edited_timestamp == ~U[2023-02-01 12:05:00Z]
    end

    @tag :fixed
    test "handles TTS message" do
      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "tts_user"})}
      end)

      message_struct =
        message(%{
          id: 111_222_333,
          content: "This is a text-to-speech message",
          author: user(%{id: 444_555_666, username: "tts_user"}),
          channel_id: 777_888_999,
          guild_id: 333_444_555,
          timestamp: "2023-03-10T15:30:00Z",
          tts: true,
          mention_everyone: false,
          pinned: false
        })

      created_message = TestApp.Discord.message_from_discord!(%{data: message_struct})

      assert created_message.discord_id == message_struct.id
      assert created_message.tts == true
    end

    @tag :fixed
    test "handles message with @everyone mention" do
      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "announcer"})}
      end)

      message_struct =
        message(%{
          id: 333_444_555,
          content: "@everyone Important announcement!",
          author: user(%{id: 666_777_888, username: "announcer"}),
          channel_id: 999_111_222,
          guild_id: 777_888_999,
          timestamp: "2023-04-05T09:00:00Z",
          tts: false,
          mention_everyone: true,
          pinned: false
        })

      created_message = TestApp.Discord.message_from_discord!(%{data: message_struct})

      assert created_message.discord_id == message_struct.id
      assert created_message.mention_everyone == true
    end

    @tag :fixed
    test "handles pinned message" do
      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "pinner"})}
      end)

      message_struct =
        message(%{
          id: 555_666_777,
          content: "This message is pinned",
          author: user(%{id: 888_999_111, username: "pinner"}),
          channel_id: 222_333_444,
          guild_id: 111_222_333,
          timestamp: "2023-05-12T14:20:00Z",
          tts: false,
          mention_everyone: false,
          pinned: true
        })

      created_message = TestApp.Discord.message_from_discord!(%{data: message_struct})

      assert created_message.discord_id == message_struct.id
      assert created_message.pinned == true
    end

    @tag :fixed
    test "handles nil content" do
      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "empty_user"})}
      end)

      message_struct =
        message(%{
          id: 777_888_999,
          content: nil,
          author: user(%{id: 111_222_333, username: "empty_user"}),
          channel_id: 444_555_666,
          guild_id: 999_888_777,
          timestamp: "2023-06-01T18:45:00Z",
          tts: false,
          mention_everyone: false,
          pinned: false
        })

      created_message = TestApp.Discord.message_from_discord!(%{data: message_struct})

      assert created_message.discord_id == message_struct.id
      assert created_message.content == nil
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches message from API when data not provided" do
      channel_id = 555_666_777
      message_id = 999_888_777
      guild_id = 111_222_333

      stub(Nostrum.Api.Message, :get, fn ^channel_id, ^message_id ->
        {:ok,
         message(%{
           id: message_id,
           channel_id: channel_id,
           guild_id: guild_id,
           content: "API fetched message",
           author: user(%{id: 123_456_789}),
           timestamp: "2023-06-15T10:00:00.000000Z",
           tts: false,
           mention_everyone: false,
           pinned: false
         })}
      end)

      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "test-guild"})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user"})}
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
      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "author"})}
      end)

      discord_id = 555_666_777

      initial_struct =
        message(%{
          id: discord_id,
          content: "Original content",
          author: user(%{id: 123_456_789, username: "author"}),
          channel_id: 111_222_333,
          guild_id: 222_333_444,
          timestamp: "2023-01-01T00:00:00Z",
          edited_timestamp: nil,
          pinned: false
        })

      {:ok, original_message} =
        TestApp.Discord.message_from_discord(%{data: initial_struct})

      updated_struct =
        message(%{
          id: discord_id,
          content: "Edited content",
          author: user(%{id: 123_456_789, username: "author"}),
          channel_id: 111_222_333,
          guild_id: 222_333_444,
          timestamp: "2023-01-01T00:00:00Z",
          edited_timestamp: "2023-01-01T00:05:00Z",
          pinned: true
        })

      {:ok, updated_message} =
        TestApp.Discord.message_from_discord(%{data: updated_struct})

      assert updated_message.id == original_message.id
      assert updated_message.discord_id == original_message.discord_id

      assert updated_message.content == "Edited content"
      assert updated_message.edited_timestamp == ~U[2023-01-01 00:05:00Z]
      assert updated_message.pinned == true
    end

    @tag :fixed
    test "upsert works with pin status changes" do
      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "important_user"})}
      end)

      discord_id = 333_444_555

      initial_struct =
        message(%{
          id: discord_id,
          content: "Important message",
          author: user(%{id: 987_654_321, username: "important_user"}),
          channel_id: 777_888_999,
          guild_id: 555_666_777,
          timestamp: "2023-07-01T10:00:00Z",
          pinned: false
        })

      {:ok, original_message} =
        TestApp.Discord.message_from_discord(%{data: initial_struct})

      updated_struct =
        message(%{
          id: discord_id,
          content: "Important message",
          author: user(%{id: 987_654_321, username: "important_user"}),
          channel_id: 777_888_999,
          guild_id: 555_666_777,
          timestamp: "2023-07-01T10:00:00Z",
          pinned: true
        })

      {:ok, updated_message} =
        TestApp.Discord.message_from_discord(%{data: updated_struct})

      assert updated_message.id == original_message.id
      assert updated_message.discord_id == discord_id

      assert updated_message.pinned == true
    end
  end
end
