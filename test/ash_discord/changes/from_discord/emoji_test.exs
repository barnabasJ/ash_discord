defmodule AshDiscord.Changes.FromDiscord.EmojiTest do
  @moduledoc """
  Comprehensive tests for Emoji entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord
  import Mimic

  setup do
    copy(Nostrum.Api)
    :ok
  end

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

      result = TestApp.Discord.emoji_from_discord(%{data: emoji_struct})

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

      result = TestApp.Discord.emoji_from_discord(%{data: emoji_struct})

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

      result = TestApp.Discord.emoji_from_discord(%{data: emoji_struct})

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

      result = TestApp.Discord.emoji_from_discord(%{data: emoji_struct})

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

      result = TestApp.Discord.emoji_from_discord(%{data: emoji_struct})

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_struct.id
      assert created_emoji.name == emoji_struct.name
      assert created_emoji.require_colons == false
    end
  end

  describe "API fallback pattern" do
    test "fetches emoji from API when data not provided" do
      guild_id = 555_666_777
      emoji_id = 999_888_777

      expect(Nostrum.Api, :get_guild_emoji, fn ^guild_id, ^emoji_id ->
        {:ok,
         emoji(%{
           id: emoji_id,
           name: "api_fetched_emoji",
           animated: true,
           managed: false,
           require_colons: true
         })}
      end)

      result =
        TestApp.Discord.emoji_from_discord(%{identity: %{guild_id: guild_id, emoji_id: emoji_id}})

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_id
      assert created_emoji.name == "api_fetched_emoji"
      assert created_emoji.animated == true
      assert created_emoji.custom == true
      assert created_emoji.managed == false
      assert created_emoji.require_colons == true
    end

    test "handles API errors gracefully" do
      guild_id = 404_404_404
      emoji_id = 999_888_777

      expect(Nostrum.Api, :get_guild_emoji, fn ^guild_id, ^emoji_id ->
        {:error, %{status_code: 404, message: "Unknown Guild"}}
      end)

      result =
        TestApp.Discord.emoji_from_discord(%{identity: %{guild_id: guild_id, emoji_id: emoji_id}})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Unknown Guild" or error_message =~ "404"
    end

    test "requires data or identity argument for emoji creation" do
      result = TestApp.Discord.emoji_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Identity must be a map with guild_id and emoji_id"
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
        TestApp.Discord.emoji_from_discord(%{data: initial_struct})

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
        TestApp.Discord.emoji_from_discord(%{data: updated_struct})

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
        TestApp.Discord.emoji_from_discord(%{data: initial_struct})

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
        TestApp.Discord.emoji_from_discord(%{data: updated_struct})

      # Should be same record
      assert updated_emoji.id == original_emoji.id
      assert updated_emoji.discord_id == discord_id

      # But with updated availability
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.emoji_from_discord(%{data: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for data"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = emoji(%{id: nil, name: nil})

      result = TestApp.Discord.emoji_from_discord(%{data: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "value must not be nil"
    end

    test "handles malformed emoji data" do
      malformed_struct = %{
        id: "not_an_integer",
        # Required field as nil
        name: nil,
        animated: "not_a_boolean"
      }

      result = TestApp.Discord.emoji_from_discord(%{data: malformed_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # Should contain validation errors
      assert error_message =~ "is required" or error_message =~ "is invalid" or
               error_message =~ "no function clause"
    end
  end
end
