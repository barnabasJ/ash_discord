defmodule AshDiscord.Changes.FromDiscord.MessageTest do
  @moduledoc """
  Comprehensive tests for Message entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord

  describe "struct-first pattern" do
    test "creates message from discord struct with all attributes" do
      Mimic.copy(Nostrum.Api.Channel)
      Mimic.copy(Nostrum.Api.Guild)
      Mimic.copy(Nostrum.Api.User)

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

      # Mock channel API call for relationship management
      Mimic.expect(Nostrum.Api.Channel, :get, fn 555_666_777 ->
        {:ok, channel(%{id: 555_666_777, name: "test-channel", type: 0})}
      end)

      # Mock guild API call for relationship management
      Mimic.expect(Nostrum.Api.Guild, :get, fn 111_222_333 ->
        {:ok, guild(%{id: 111_222_333, name: "Test Guild"})}
      end)

      # Mock user API call for author relationship management
      Mimic.expect(Nostrum.Api.User, :get, fn 987_654_321 ->
        {:ok, user(%{id: 987_654_321, username: "test_user"})}
      end)

      result = TestApp.Discord.message_from_discord(%{data: message_struct})

      assert {:ok, created_message} = result
      assert created_message.discord_id == message_struct.id
      assert created_message.content == message_struct.content
      assert created_message.author_id == message_struct.author.id
      assert created_message.channel_id == message_struct.channel_id
      assert created_message.guild_id == message_struct.guild_id
      assert created_message.timestamp == ~U[2023-01-15 10:30:00Z]
      assert created_message.edited_timestamp == nil
      assert created_message.tts == false
      assert created_message.mention_everyone == false
      assert created_message.pinned == false
    end

    test "handles edited message" do
      Mimic.copy(Nostrum.Api.Channel)
      Mimic.copy(Nostrum.Api.Guild)
      Mimic.copy(Nostrum.Api.User)

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

      # Mock channel API call for relationship management
      Mimic.expect(Nostrum.Api.Channel, :get, fn 777_888_999 ->
        {:ok, channel(%{id: 777_888_999, name: "test-channel", type: 0})}
      end)

      # Mock guild API call for relationship management
      Mimic.expect(Nostrum.Api.Guild, :get, fn 555_666_777 ->
        {:ok, guild(%{id: 555_666_777, name: "Test Guild"})}
      end)

      # Mock user API call for author relationship management
      Mimic.expect(Nostrum.Api.User, :get, fn 123_456_789 ->
        {:ok, user(%{id: 123_456_789, username: "editor"})}
      end)

      result = TestApp.Discord.message_from_discord(%{data: message_struct})

      assert {:ok, created_message} = result
      assert created_message.discord_id == message_struct.id
      assert created_message.content == message_struct.content
      assert created_message.timestamp == ~U[2023-02-01 12:00:00Z]
      assert created_message.edited_timestamp == ~U[2023-02-01 12:05:00Z]
    end

    test "handles TTS message" do
      Mimic.copy(Nostrum.Api.Channel)
      Mimic.copy(Nostrum.Api.Guild)
      Mimic.copy(Nostrum.Api.User)

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

      # Mock channel API call for relationship management
      Mimic.expect(Nostrum.Api.Channel, :get, fn 777_888_999 ->
        {:ok, channel(%{id: 777_888_999, name: "test-channel", type: 0})}
      end)

      # Mock guild API call for relationship management
      Mimic.expect(Nostrum.Api.Guild, :get, fn 333_444_555 ->
        {:ok, guild(%{id: 333_444_555, name: "Test Guild"})}
      end)

      # Mock user API call for author relationship management
      Mimic.expect(Nostrum.Api.User, :get, fn 444_555_666 ->
        {:ok, user(%{id: 444_555_666, username: "tts_user"})}
      end)

      result = TestApp.Discord.message_from_discord(%{data: message_struct})

      assert {:ok, created_message} = result
      assert created_message.discord_id == message_struct.id
      assert created_message.tts == true
    end

    test "handles message with @everyone mention" do
      Mimic.copy(Nostrum.Api.Channel)
      Mimic.copy(Nostrum.Api.Guild)
      Mimic.copy(Nostrum.Api.User)

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

      # Mock channel API call for relationship management
      Mimic.expect(Nostrum.Api.Channel, :get, fn 999_111_222 ->
        {:ok, channel(%{id: 999_111_222, name: "test-channel", type: 0})}
      end)

      # Mock guild API call for relationship management
      Mimic.expect(Nostrum.Api.Guild, :get, fn 777_888_999 ->
        {:ok, guild(%{id: 777_888_999, name: "Test Guild"})}
      end)

      # Mock user API call for author relationship management
      Mimic.expect(Nostrum.Api.User, :get, fn 666_777_888 ->
        {:ok, user(%{id: 666_777_888, username: "announcer"})}
      end)

      result = TestApp.Discord.message_from_discord(%{data: message_struct})

      assert {:ok, created_message} = result
      assert created_message.discord_id == message_struct.id
      assert created_message.mention_everyone == true
    end

    test "handles pinned message" do
      Mimic.copy(Nostrum.Api.Channel)
      Mimic.copy(Nostrum.Api.Guild)
      Mimic.copy(Nostrum.Api.User)

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

      # Mock channel API call for relationship management
      Mimic.expect(Nostrum.Api.Channel, :get, fn 222_333_444 ->
        {:ok, channel(%{id: 222_333_444, name: "test-channel", type: 0})}
      end)

      # Mock guild API call for relationship management
      Mimic.expect(Nostrum.Api.Guild, :get, fn 111_222_333 ->
        {:ok, guild(%{id: 111_222_333, name: "Test Guild"})}
      end)

      # Mock user API call for author relationship management
      Mimic.expect(Nostrum.Api.User, :get, fn 888_999_111 ->
        {:ok, user(%{id: 888_999_111, username: "pinner"})}
      end)

      result = TestApp.Discord.message_from_discord(%{data: message_struct})

      assert {:ok, created_message} = result
      assert created_message.discord_id == message_struct.id
      assert created_message.pinned == true
    end

    test "handles empty message content" do
      Mimic.copy(Nostrum.Api.Channel)
      Mimic.copy(Nostrum.Api.Guild)
      Mimic.copy(Nostrum.Api.User)

      message_struct =
        message(%{
          id: 777_888_999,
          content: "",
          author: user(%{id: 111_222_333, username: "empty_user"}),
          channel_id: 444_555_666,
          guild_id: 999_888_777,
          timestamp: "2023-06-01T18:45:00Z",
          tts: false,
          mention_everyone: false,
          pinned: false
        })

      # Mock channel API call for relationship management
      Mimic.expect(Nostrum.Api.Channel, :get, fn 444_555_666 ->
        {:ok, channel(%{id: 444_555_666, name: "test-channel", type: 0})}
      end)

      # Mock guild API call for relationship management
      Mimic.expect(Nostrum.Api.Guild, :get, fn 999_888_777 ->
        {:ok, guild(%{id: 999_888_777, name: "Test Guild"})}
      end)

      # Mock user API call for author relationship management
      Mimic.expect(Nostrum.Api.User, :get, fn 111_222_333 ->
        {:ok, user(%{id: 111_222_333, username: "empty_user"})}
      end)

      result = TestApp.Discord.message_from_discord(%{data: message_struct})

      assert {:ok, created_message} = result
      assert created_message.discord_id == message_struct.id
      assert created_message.content == nil
    end
  end

  describe "API fallback pattern" do
    test "message API fallback is not supported" do
      # Messages don't support direct API fetching in our implementation
      discord_id = 999_888_777

      result = TestApp.Discord.message_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Failed to fetch message with ID #{discord_id}"
      assert error_message =~ ":requires_channel_and_message_ids"
    end

    test "requires discord_struct for message creation" do
      result = TestApp.Discord.message_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord ID found for message entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing message instead of creating duplicate" do
      Mimic.copy(Nostrum.Api.Channel)
      Mimic.copy(Nostrum.Api.Guild)
      Mimic.copy(Nostrum.Api.User)

      discord_id = 555_666_777

      # Mock channel API call for relationship management
      Mimic.expect(Nostrum.Api.Channel, :get, fn 111_222_333 ->
        {:ok, channel(%{id: 111_222_333, name: "test-channel", type: 0})}
      end)

      # Mock guild API call for relationship management
      Mimic.expect(Nostrum.Api.Guild, :get, fn 222_333_444 ->
        {:ok, guild(%{id: 222_333_444, name: "Test Guild"})}
      end)

      # Mock user API call for author relationship management
      Mimic.expect(Nostrum.Api.User, :get, fn 123_456_789 ->
        {:ok, user(%{id: 123_456_789, username: "author"})}
      end)

      # Create initial message
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

      # Update same message with edited content
      updated_struct =
        message(%{
          # Same ID
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

      # Should be same record (same Ash ID)
      assert updated_message.id == original_message.id
      assert updated_message.discord_id == original_message.discord_id

      # But with updated attributes
      assert updated_message.content == "Edited content"
      assert updated_message.edited_timestamp == ~U[2023-01-01 00:05:00Z]
      assert updated_message.pinned == true
    end

    test "upsert works with pin status changes" do
      Mimic.copy(Nostrum.Api.Channel)
      Mimic.copy(Nostrum.Api.Guild)
      Mimic.copy(Nostrum.Api.User)

      discord_id = 333_444_555

      # Mock channel API call for relationship management
      Mimic.expect(Nostrum.Api.Channel, :get, fn 777_888_999 ->
        {:ok, channel(%{id: 777_888_999, name: "test-channel", type: 0})}
      end)

      # Mock guild API call for relationship management
      Mimic.expect(Nostrum.Api.Guild, :get, fn 555_666_777 ->
        {:ok, guild(%{id: 555_666_777, name: "Test Guild"})}
      end)

      # Mock user API call for author relationship management
      Mimic.expect(Nostrum.Api.User, :get, fn 987_654_321 ->
        {:ok, user(%{id: 987_654_321, username: "important_user"})}
      end)

      # Create initial unpinned message
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

      # Pin the message
      updated_struct =
        message(%{
          # Same ID
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

      # Should be same record
      assert updated_message.id == original_message.id
      assert updated_message.discord_id == discord_id

      # But with updated pin status
      assert updated_message.pinned == true
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.message_from_discord(%{data: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = message(%{id: nil, name: nil})

      result = TestApp.Discord.message_from_discord(%{data: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles invalid timestamp format" do
      message_struct =
        message(%{
          id: 123_456_789,
          content: "Test message",
          author: user(%{id: 987_654_321, username: "test_user"}),
          channel_id: 555_666_777,
          # Invalid timestamp format
          timestamp: "not_a_datetime",
          tts: false,
          mention_everyone: false,
          pinned: false
        })

      result = TestApp.Discord.message_from_discord(%{data: message_struct})

      # This might succeed with nil timestamp or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_message} ->
          # If it succeeds, timestamp should be handled gracefully
          assert created_message.discord_id == message_struct.id

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end

    test "handles missing author in discord_struct" do
      invalid_struct = %{
        id: 123_456_789,
        content: "Test message",
        # Missing author field
        channel_id: 555_666_777,
        timestamp: "2023-01-01T00:00:00Z"
      }

      result = TestApp.Discord.message_from_discord(%{data: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required" or error_message =~ "author"
    end
  end
end
