defmodule AshDiscord.Changes.FromDiscord.TypingIndicatorTest do
  @moduledoc """
  Comprehensive tests for TypingIndicator entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord



  describe "struct-first pattern" do
    test "creates typing indicator from discord struct with all attributes" do
      typing_struct =
        typing_indicator(%{
          user_id: 123_456_789,
          channel_id: 555_666_777,
          guild_id: 111_222_333,
          timestamp: 1_673_784_600
        })

      result = TestApp.Discord.typing_indicator_from_discord(%{discord_struct: typing_struct})

      assert {:ok, created_typing} = result
      assert created_typing.user_id == typing_struct.user_id
      assert created_typing.channel_id == typing_struct.channel_id
      assert created_typing.guild_id == typing_struct.guild_id
      assert created_typing.timestamp == typing_struct.timestamp
    end

    test "handles DM typing indicator without guild_id" do
      typing_struct =
        typing_indicator(%{
          user_id: 987_654_321,
          channel_id: 777_888_999,
          # No guild for DM
          guild_id: nil,
          timestamp: 1_673_788_200
        })

      result = TestApp.Discord.typing_indicator_from_discord(%{discord_struct: typing_struct})

      assert {:ok, created_typing} = result
      assert created_typing.user_id == typing_struct.user_id
      assert created_typing.channel_id == typing_struct.channel_id
      assert created_typing.guild_id == nil
      assert created_typing.timestamp == typing_struct.timestamp
    end

    test "handles recent typing indicator" do
      # Current timestamp
      current_timestamp = System.system_time(:second)

      typing_struct =
        typing_indicator(%{
          user_id: 111_222_333,
          channel_id: 444_555_666,
          guild_id: 777_888_999,
          timestamp: current_timestamp
        })

      result = TestApp.Discord.typing_indicator_from_discord(%{discord_struct: typing_struct})

      assert {:ok, created_typing} = result
      assert created_typing.user_id == typing_struct.user_id
      assert created_typing.timestamp == current_timestamp
    end

    test "handles old typing indicator" do
      # Old timestamp (1 hour ago)
      old_timestamp = System.system_time(:second) - 3600

      typing_struct =
        typing_indicator(%{
          user_id: 333_444_555,
          channel_id: 666_777_888,
          guild_id: 999_111_222,
          timestamp: old_timestamp
        })

      result = TestApp.Discord.typing_indicator_from_discord(%{discord_struct: typing_struct})

      assert {:ok, created_typing} = result
      assert created_typing.user_id == typing_struct.user_id
      assert created_typing.timestamp == old_timestamp
    end

    test "handles typing indicator in voice channel" do
      typing_struct =
        typing_indicator(%{
          user_id: 555_666_777,
          # Voice channel
          channel_id: 888_999_111,
          guild_id: 222_333_444,
          timestamp: 1_673_792_200
        })

      result = TestApp.Discord.typing_indicator_from_discord(%{discord_struct: typing_struct})

      assert {:ok, created_typing} = result
      assert created_typing.user_id == typing_struct.user_id
      assert created_typing.channel_id == 888_999_111
    end

    test "handles typing indicator in thread" do
      typing_struct =
        typing_indicator(%{
          user_id: 777_888_999,
          # Thread channel
          channel_id: 111_333_555,
          guild_id: 444_666_888,
          timestamp: 1_673_795_800
        })

      result = TestApp.Discord.typing_indicator_from_discord(%{discord_struct: typing_struct})

      assert {:ok, created_typing} = result
      assert created_typing.user_id == typing_struct.user_id
      assert created_typing.channel_id == 111_333_555
    end
  end

  describe "API fallback pattern" do

    test "typing indicator API fallback is not supported" do
      # Typing indicators don't support direct API fetching in our implementation
      discord_id = 999_888_777

      result = TestApp.Discord.typing_indicator_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      assert error.message =~ "Failed to fetch typing_indicator with ID #{discord_id}"
      assert error.message =~ ":unsupported_type"
    end

    test "requires discord_struct for typing indicator creation" do
      result = TestApp.Discord.typing_indicator_from_discord(%{})

      assert {:error, error} = result
      assert error.message =~ "No Discord ID found for typing_indicator entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing typing indicator instead of creating duplicate" do
      user_id = 555_666_777
      channel_id = 111_222_333

      # Create initial typing indicator
      initial_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: 444_555_666,
          timestamp: 1_673_784_600
        })

      {:ok, original_typing} =
        TestApp.Discord.typing_indicator_from_discord(%{discord_struct: initial_struct})

      # Update same user's typing in same channel with new timestamp
      updated_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: 444_555_666,
          timestamp: 1_673_788_200
        })

      {:ok, updated_typing} =
        TestApp.Discord.typing_indicator_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_typing.id == original_typing.id
      assert updated_typing.user_id == original_typing.user_id
      assert updated_typing.channel_id == original_typing.channel_id

      # But with updated timestamp
      assert updated_typing.timestamp == 1_673_788_200

      # Verify only one typing indicator record exists for this user in this channel
      all_typings = TestApp.Discord.TypingIndicator.read!()

      typings_with_user_and_channel =
        Enum.filter(all_typings, &(&1.user_id == user_id and &1.channel_id == channel_id))

      assert length(typings_with_user_and_channel) == 1
    end

    test "upsert works with guild context changes" do
      user_id = 333_444_555
      channel_id = 777_888_999

      # Create initial typing in guild channel
      initial_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: 111_222_333,
          timestamp: 1_673_784_600
        })

      {:ok, original_typing} =
        TestApp.Discord.typing_indicator_from_discord(%{discord_struct: initial_struct})

      # Update same typing (channel moved to different guild context)
      updated_struct =
        typing_indicator(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: 666_777_888,
          timestamp: 1_673_788_200
        })

      {:ok, updated_typing} =
        TestApp.Discord.typing_indicator_from_discord(%{discord_struct: updated_struct})

      # Should be same record
      assert updated_typing.id == original_typing.id
      assert updated_typing.user_id == user_id
      assert updated_typing.channel_id == channel_id

      # But with updated guild and timestamp
      assert updated_typing.guild_id == 666_777_888
      assert updated_typing.timestamp == 1_673_788_200

      # Verify only one typing indicator record exists
      all_typings = TestApp.Discord.TypingIndicator.read!()

      typings_with_user_and_channel =
        Enum.filter(all_typings, &(&1.user_id == user_id and &1.channel_id == channel_id))

      assert length(typings_with_user_and_channel) == 1
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.typing_indicator_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = %{}

      result = TestApp.Discord.typing_indicator_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles invalid user_id in discord_struct" do
      invalid_struct = %{
        # Invalid user_id type
        user_id: "not_an_integer",
        channel_id: 555_666_777,
        guild_id: 111_222_333,
        timestamp: 1_673_784_600
      }

      result = TestApp.Discord.typing_indicator_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is invalid" or error_message =~ "must be"
    end

    test "handles invalid timestamp in discord_struct" do
      typing_struct =
        typing_indicator(%{
          user_id: 123_456_789,
          channel_id: 555_666_777,
          guild_id: 111_222_333,
          # Invalid timestamp type
          timestamp: "not_an_integer"
        })

      result = TestApp.Discord.typing_indicator_from_discord(%{discord_struct: typing_struct})

      # This might succeed with normalized timestamp or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_typing} ->
          # If it succeeds, timestamp should be handled gracefully
          assert created_typing.user_id == typing_struct.user_id

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end

    test "handles malformed typing indicator data" do
      malformed_struct = %{
        user_id: "not_an_integer",
        channel_id: "not_an_integer",
        timestamp: "not_an_integer"
      }

      result =
        TestApp.Discord.typing_indicator_from_discord(%{discord_struct: malformed_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # Should contain validation errors
      assert error_message =~ "is invalid" or error_message =~ "must be"
    end
  end
end
