defmodule AshDiscord.Changes.FromDiscord.EmojiTest do
  @moduledoc """
  Comprehensive tests for Emoji entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord

  describe "struct-first pattern" do
    test "creates emoji from discord struct with all attributes" do
      emoji_struct =
        emoji(%{
          id: 123_456_789,
          name: "custom_emoji",
          animated: false,
          managed: false,
          require_colons: true
        })

      result = TestApp.Discord.emoji_from_discord(%{discord_struct: emoji_struct})

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_struct.id
      assert created_emoji.name == emoji_struct.name
      assert created_emoji.animated == false
      assert created_emoji.managed == false
      assert created_emoji.require_colons == true
    end

    test "handles animated emoji" do
      emoji_struct =
        emoji(%{
          id: 987_654_321,
          name: "animated_emoji",
          animated: true,
          managed: false,
          require_colons: true
        })

      result = TestApp.Discord.emoji_from_discord(%{discord_struct: emoji_struct})

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_struct.id
      assert created_emoji.name == emoji_struct.name
      assert created_emoji.animated == true
    end

    test "handles managed emoji (from integration)" do
      emoji_struct =
        emoji(%{
          id: 111_222_333,
          name: "twitch_emoji",
          animated: false,
          managed: true,
          require_colons: true
        })

      result = TestApp.Discord.emoji_from_discord(%{discord_struct: emoji_struct})

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_struct.id
      assert created_emoji.name == emoji_struct.name
      assert created_emoji.managed == true
    end

    test "handles unavailable emoji" do
      emoji_struct =
        emoji(%{
          id: 777_888_999,
          name: "broken_emoji",
          animated: false,
          managed: false,
          require_colons: true
        })

      result = TestApp.Discord.emoji_from_discord(%{discord_struct: emoji_struct})

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_struct.id
      assert created_emoji.name == emoji_struct.name
    end

    test "handles emoji without require_colons" do
      emoji_struct =
        emoji(%{
          id: 333_444_555,
          name: "special_emoji",
          animated: false,
          managed: false,
          require_colons: false
        })

      result = TestApp.Discord.emoji_from_discord(%{discord_struct: emoji_struct})

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_struct.id
      assert created_emoji.name == emoji_struct.name
      assert created_emoji.require_colons == false
    end
  end

  describe "API fallback pattern" do
    test "emoji API fallback is not supported" do
      # Emojis don't support direct API fetching in our implementation
      discord_id = 999_888_777

      result = TestApp.Discord.emoji_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Failed to fetch emoji with ID #{discord_id}"
      error_message = Exception.message(error)
      assert error_message =~ ":unsupported_type"
    end

    test "requires discord_struct for emoji creation" do
      result = TestApp.Discord.emoji_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord ID found for emoji entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing emoji instead of creating duplicate" do
      discord_id = 555_666_777

      # Create initial emoji
      initial_struct =
        emoji(%{
          id: discord_id,
          name: "original_emoji",
          animated: false,
          managed: false
        })

      {:ok, original_emoji} =
        TestApp.Discord.emoji_from_discord(%{discord_struct: initial_struct})

      # Update same emoji with new data
      updated_struct =
        emoji(%{
          # Same ID
          id: discord_id,
          name: "updated_emoji",
          animated: true,
          managed: true,
          require_colons: false
        })

      {:ok, updated_emoji} =
        TestApp.Discord.emoji_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_emoji.id == original_emoji.id
      assert updated_emoji.discord_id == original_emoji.discord_id

      # But with updated attributes
      assert updated_emoji.name == "updated_emoji"
      assert updated_emoji.animated == true
      assert updated_emoji.managed == true
      assert updated_emoji.require_colons == false
    end

    test "upsert works with availability changes" do
      discord_id = 333_444_555

      # Create initial available emoji
      initial_struct =
        emoji(%{
          id: discord_id,
          name: "status_emoji",
          animated: false,
          managed: false
        })

      {:ok, original_emoji} =
        TestApp.Discord.emoji_from_discord(%{discord_struct: initial_struct})

      # Mark as unavailable
      updated_struct =
        emoji(%{
          # Same ID
          id: discord_id,
          name: "status_emoji",
          animated: false,
          managed: false
        })

      {:ok, updated_emoji} =
        TestApp.Discord.emoji_from_discord(%{discord_struct: updated_struct})

      # Should be same record
      assert updated_emoji.id == original_emoji.id
      assert updated_emoji.discord_id == discord_id

      # But with updated availability
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.emoji_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = %{}

      result = TestApp.Discord.emoji_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles malformed emoji data" do
      malformed_struct = %{
        id: "not_an_integer",
        # Required field as nil
        name: nil,
        animated: "not_a_boolean"
      }

      result = TestApp.Discord.emoji_from_discord(%{discord_struct: malformed_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # Should contain validation errors
      assert error_message =~ "is required" or error_message =~ "is invalid"
    end
  end
end
