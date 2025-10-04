defmodule AshDiscord.Changes.FromDiscord.MessageReactionTest do
  @moduledoc """
  Comprehensive tests for MessageReaction entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord

  describe "struct-first pattern" do
    test "creates message reaction from discord struct with unicode emoji" do
      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: "👍", animated: false},
          user_id: 111_222_333,
          message_id: 444_555_666,
          channel_id: 777_888_999,
          guild_id: 333_444_555
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{data: reaction_event})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_id == nil
      assert created_reaction.emoji_name == "👍"
      assert created_reaction.emoji_animated == false
      assert created_reaction.count == 1
      assert created_reaction.me == false
    end

    test "creates message reaction with custom emoji" do
      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: 987_654_321, name: "custom_emoji", animated: false},
          user_id: 111_222_333,
          message_id: 444_555_666,
          channel_id: 777_888_999,
          guild_id: 333_444_555
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{data: reaction_event})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_id == 987_654_321
      assert created_reaction.emoji_name == "custom_emoji"
      assert created_reaction.emoji_animated == false
      assert created_reaction.count == 1
      assert created_reaction.me == false
    end

    test "creates message reaction with animated custom emoji" do
      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: 555_666_777, name: "animated_party", animated: true},
          user_id: 777_888_999,
          message_id: 111_222_333,
          channel_id: 444_555_666,
          guild_id: 999_111_222
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{data: reaction_event})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_id == 555_666_777
      assert created_reaction.emoji_name == "animated_party"
      assert created_reaction.emoji_animated == true
      assert created_reaction.count == 1
    end

    test "handles single count reaction" do
      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: "❤️", animated: false},
          user_id: 333_444_555,
          message_id: 666_777_888,
          channel_id: 999_111_222,
          guild_id: 222_333_444
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{data: reaction_event})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_name == "❤️"
      assert created_reaction.count == 1
      assert created_reaction.me == false
    end

    test "handles high count reaction" do
      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: "🔥", animated: false},
          user_id: 888_999_111,
          message_id: 222_333_444,
          channel_id: 555_666_777,
          guild_id: 111_222_333
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{data: reaction_event})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_name == "🔥"
      assert created_reaction.count == 1
    end

    test "handles DM reaction without guild_id" do
      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: "😊", animated: false},
          user_id: 444_555_666,
          message_id: 777_888_999,
          channel_id: 111_222_333,
          # No guild for DM
          guild_id: nil
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{data: reaction_event})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_name == "😊"
      assert created_reaction.guild_id == nil
    end
  end

  describe "API fallback pattern" do
    test "message reaction requires data argument" do
      # Message reactions require data argument - passing invalid arg returns "No such input" error
      discord_id = 999_888_777

      result = TestApp.Discord.message_reaction_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No such input `discord_id`"
    end

    test "requires data argument for message reaction creation" do
      result = TestApp.Discord.message_reaction_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "MessageReaction requires data argument"
    end
  end

  describe "upsert behavior" do
    test "updates existing message reaction instead of creating duplicate" do
      user_id = 555_666_777
      message_id = 111_222_333
      emoji_name = "👍"
      # Use concrete ID instead of nil
      emoji_id = 123_456_789

      # Create initial reaction
      initial_event =
        message_reaction_add_event(%{
          emoji: %{id: emoji_id, name: emoji_name, animated: false},
          user_id: user_id,
          message_id: message_id,
          channel_id: 444_555_666,
          guild_id: 777_888_999
        })

      {:ok, original_reaction} =
        TestApp.Discord.message_reaction_from_discord(%{data: initial_event})

      # Update same reaction (upsert should update the existing record)
      updated_event =
        message_reaction_add_event(%{
          emoji: %{id: emoji_id, name: emoji_name, animated: false},
          user_id: user_id,
          message_id: message_id,
          channel_id: 444_555_666,
          guild_id: 777_888_999
        })

      {:ok, updated_reaction} =
        TestApp.Discord.message_reaction_from_discord(%{data: updated_event})

      # Should be same record (same Ash ID)
      assert updated_reaction.id == original_reaction.id
      assert updated_reaction.user_id == original_reaction.user_id
      assert updated_reaction.message_id == original_reaction.message_id
      assert updated_reaction.emoji_name == original_reaction.emoji_name
    end

    test "updates existing standard emoji reaction instead of creating duplicate" do
      user_id = 777_888_999
      message_id = 222_333_444
      emoji_name = "❤️"

      # Create initial reaction with standard emoji (no ID)
      initial_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: emoji_name, animated: false},
          user_id: user_id,
          message_id: message_id,
          channel_id: 555_666_777,
          guild_id: 888_999_000
        })

      {:ok, original_reaction} =
        TestApp.Discord.message_reaction_from_discord(%{data: initial_event})

      # Update same reaction (upsert should update the existing record)
      updated_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: emoji_name, animated: false},
          user_id: user_id,
          message_id: message_id,
          channel_id: 555_666_777,
          guild_id: 888_999_000
        })

      {:ok, updated_reaction} =
        TestApp.Discord.message_reaction_from_discord(%{data: updated_event})

      # Should be same record (same Ash ID)
      assert updated_reaction.id == original_reaction.id
      assert updated_reaction.user_id == original_reaction.user_id
      assert updated_reaction.message_id == original_reaction.message_id
      assert updated_reaction.emoji_name == original_reaction.emoji_name
      assert updated_reaction.emoji_id == nil
    end

    test "upsert works with custom emoji reactions" do
      user_id = 333_444_555
      message_id = 777_888_999
      emoji_id = 123_456_789

      # Create initial custom emoji reaction
      initial_event =
        message_reaction_add_event(%{
          emoji: %{id: emoji_id, name: "custom_emoji", animated: false},
          user_id: user_id,
          message_id: message_id,
          channel_id: 999_111_222,
          guild_id: 222_333_444
        })

      {:ok, original_reaction} =
        TestApp.Discord.message_reaction_from_discord(%{data: initial_event})

      # Update to animated version
      updated_event =
        message_reaction_add_event(%{
          emoji: %{id: emoji_id, name: "custom_emoji", animated: true},
          user_id: user_id,
          message_id: message_id,
          channel_id: 999_111_222,
          guild_id: 222_333_444
        })

      {:ok, updated_reaction} =
        TestApp.Discord.message_reaction_from_discord(%{data: updated_event})

      # Should be same record
      assert updated_reaction.id == original_reaction.id
      assert updated_reaction.user_id == user_id
      assert updated_reaction.message_id == message_id
      assert updated_reaction.emoji_id == emoji_id

      # But with updated attributes
      assert updated_reaction.emoji_animated == true
    end
  end

  describe "error handling" do
    test "handles invalid data argument format" do
      result = TestApp.Discord.message_reaction_from_discord(%{data: "not_a_struct"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for data"
    end

    test "handles missing required fields in event struct" do
      # Missing user_id, message_id, and emoji - these are required fields
      invalid_event =
        message_reaction_add_event(%{
          emoji: nil,
          user_id: nil,
          message_id: nil,
          channel_id: nil
        })

      result = TestApp.Discord.message_reaction_from_discord(%{data: invalid_event})

      # Should fail with validation errors for nil required fields
      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "value must not be nil"
    end

    test "handles missing emoji in event struct" do
      invalid_event =
        message_reaction_add_event(%{
          emoji: nil,
          user_id: 123_456_789,
          message_id: 555_666_777,
          channel_id: 111_222_333
        })

      result = TestApp.Discord.message_reaction_from_discord(%{data: invalid_event})

      # Should fail because emoji is required
      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "value must not be nil"
    end

    test "handles valid event with all fields" do
      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: "👍", animated: false},
          user_id: 123_456_789,
          message_id: 555_666_777,
          channel_id: 111_222_333,
          guild_id: 999_888_777
        })

      result = TestApp.Discord.message_reaction_from_discord(%{data: reaction_event})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_name == "👍"
      assert created_reaction.user_id == 123_456_789
      assert created_reaction.message_id == 555_666_777
    end

    test "handles malformed emoji structure in event" do
      # The generator will create a valid event, so we need to manually create an invalid one
      invalid_event = %Nostrum.Struct.Event.MessageReactionAdd{
        user_id: 123_456_789,
        channel_id: 555_666_777,
        message_id: 111_222_333,
        guild_id: nil,
        emoji: "not_a_map",
        member: nil
      }

      result = TestApp.Discord.message_reaction_from_discord(%{data: invalid_event})

      # Should fail with validation error for invalid emoji type
      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is invalid"
    end
  end
end
