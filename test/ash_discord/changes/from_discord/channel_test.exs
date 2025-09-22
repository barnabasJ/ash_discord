defmodule AshDiscord.Changes.FromDiscord.ChannelTest do
  @moduledoc """
  Comprehensive tests for Channel entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  Special focus on permission overwrites transformation.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord

  describe "struct-first pattern" do
    test "creates channel from discord struct with all attributes" do
      channel_struct =
        channel(%{
          id: 123_456_789,
          name: "test-channel",
          # Text channel
          type: 0,
          position: 1,
          topic: "A test channel topic",
          nsfw: false,
          parent_id: 987_654_321,
          guild_id: 555_666_777
        })

      result = TestApp.Discord.channel_from_discord(%{discord_struct: channel_struct})

      assert {:ok, created_channel} = result
      assert created_channel.discord_id == channel_struct.id
      assert created_channel.name == channel_struct.name
      assert created_channel.type == channel_struct.type
      assert created_channel.position == channel_struct.position
      assert created_channel.topic == channel_struct.topic
      assert created_channel.nsfw == false
      assert created_channel.parent_id == channel_struct.parent_id
      assert created_channel.guild_id == channel_struct.guild_id
    end

    test "handles permission overwrites transformation" do
      channel_struct =
        channel(%{
          id: 111_222_333,
          name: "channel-with-permissions",
          type: 0,
          permission_overwrites: [
            # Role overwrite
            %{id: 123, type: 0, allow: 1024, deny: 0},
            # Member overwrite
            %{id: 456, type: 1, allow: 0, deny: 2048},
            # Another role
            %{id: 789, type: 0, allow: 8, deny: 1024}
          ]
        })

      result = TestApp.Discord.channel_from_discord(%{discord_struct: channel_struct})

      assert {:ok, created_channel} = result
      assert created_channel.discord_id == channel_struct.id
      assert created_channel.name == channel_struct.name

      # Verify permission overwrites transformation
      overwrites = created_channel.permission_overwrites
      assert length(overwrites) == 3

      # Check first overwrite (role)
      first_overwrite = Enum.find(overwrites, &(&1["id"] == 123))
      assert first_overwrite["type"] == 0
      assert first_overwrite["allow"] == "1024"
      assert first_overwrite["deny"] == "0"

      # Check second overwrite (member)
      second_overwrite = Enum.find(overwrites, &(&1["id"] == 456))
      assert second_overwrite["type"] == 1
      assert second_overwrite["allow"] == "0"
      assert second_overwrite["deny"] == "2048"
    end

    test "handles nil and empty permission overwrites" do
      channel_struct =
        channel(%{
          id: 444_555_666,
          name: "channel-no-permissions",
          type: 0,
          permission_overwrites: nil
        })

      result = TestApp.Discord.channel_from_discord(%{discord_struct: channel_struct})

      assert {:ok, created_channel} = result
      assert created_channel.permission_overwrites == []
    end

    test "handles voice channel type" do
      voice_channel_struct =
        channel(%{
          id: 777_888_999,
          name: "Voice Channel",
          # Voice channel
          type: 2,
          position: 5,
          guild_id: 111_222_333
        })

      result = TestApp.Discord.channel_from_discord(%{discord_struct: voice_channel_struct})

      assert {:ok, created_channel} = result
      assert created_channel.discord_id == voice_channel_struct.id
      assert created_channel.name == voice_channel_struct.name
      assert created_channel.type == 2
      assert created_channel.position == 5
    end

    test "handles category channel with children" do
      category_struct =
        channel(%{
          id: 333_444_555,
          name: "Category",
          # Category channel
          type: 4,
          position: 0
        })

      result = TestApp.Discord.channel_from_discord(%{discord_struct: category_struct})

      assert {:ok, created_channel} = result
      assert created_channel.discord_id == category_struct.id
      assert created_channel.name == category_struct.name
      assert created_channel.type == 4
    end
  end

  describe "API fallback pattern" do
    test "channel API fallback fails when API is unavailable" do
      # Channel API fetching is supported but may fail in test environment
      discord_id = 999_888_777

      result = TestApp.Discord.channel_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Failed to fetch channel with ID #{discord_id}"
      assert error_message =~ ":api_unavailable"
    end

    test "requires discord_struct for channel creation" do
      result = TestApp.Discord.channel_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord ID found for channel entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing channel instead of creating duplicate" do
      discord_id = 555_666_777

      # Create initial channel
      initial_struct =
        channel(%{
          id: discord_id,
          name: "original-channel",
          type: 0,
          topic: "Original topic"
        })

      {:ok, original_channel} =
        TestApp.Discord.channel_from_discord(%{discord_struct: initial_struct})

      # Update same channel with new data
      updated_struct =
        channel(%{
          # Same ID
          id: discord_id,
          name: "updated-channel",
          type: 0,
          topic: "Updated topic",
          position: 5,
          nsfw: true
        })

      {:ok, updated_channel} =
        TestApp.Discord.channel_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_channel.id == original_channel.id
      assert updated_channel.discord_id == original_channel.discord_id

      # But with updated attributes
      assert updated_channel.name == "updated-channel"
      assert updated_channel.topic == "Updated topic"
      assert updated_channel.position == 5
      assert updated_channel.nsfw == true
    end

    test "upsert works with permission overwrites changes" do
      discord_id = 333_444_555

      # Create initial channel with permissions
      initial_struct =
        channel(%{
          id: discord_id,
          name: "permissions-channel",
          type: 0,
          permission_overwrites: [
            %{id: 123, type: 0, allow: 1024, deny: 0}
          ]
        })

      {:ok, original_channel} =
        TestApp.Discord.channel_from_discord(%{discord_struct: initial_struct})

      # Update with different permissions
      updated_struct =
        channel(%{
          # Same ID
          id: discord_id,
          name: "permissions-channel",
          type: 0,
          permission_overwrites: [
            # Updated permissions
            %{id: 123, type: 0, allow: 2048, deny: 1024},
            # New member permission
            %{id: 456, type: 1, allow: 8, deny: 0}
          ]
        })

      {:ok, updated_channel} =
        TestApp.Discord.channel_from_discord(%{discord_struct: updated_struct})

      # Should be same record
      assert updated_channel.id == original_channel.id
      assert updated_channel.discord_id == discord_id

      # But with updated permissions
      overwrites = updated_channel.permission_overwrites
      assert length(overwrites) == 2

      # Check updated role permission
      role_overwrite = Enum.find(overwrites, &(&1["id"] == 123))
      assert role_overwrite["allow"] == "2048"
      assert role_overwrite["deny"] == "1024"

      # Check new member permission
      member_overwrite = Enum.find(overwrites, &(&1["id"] == 456))
      assert member_overwrite["type"] == 1
      assert member_overwrite["allow"] == "8"
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.channel_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = channel(%{id: nil, name: nil})

      result = TestApp.Discord.channel_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles malformed permission overwrites" do
      # Test with malformed permission overwrites structure
      channel_struct =
        channel(%{
          id: 123_456_789,
          name: "test-channel",
          type: 0,
          # Should be a list
          permission_overwrites: "not_a_list"
        })

      # The transformation should handle this gracefully
      result = TestApp.Discord.channel_from_discord(%{discord_struct: channel_struct})

      # This might succeed with empty permissions or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_channel} ->
          # If it succeeds, permissions should be normalized
          assert is_list(created_channel.permission_overwrites)

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end
  end
end
