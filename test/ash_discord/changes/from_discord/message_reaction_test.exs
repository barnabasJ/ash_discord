defmodule AshDiscord.Changes.FromDiscord.MessageReactionTest do
  @moduledoc """
  Comprehensive tests for MessageReaction entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord



  describe "struct-first pattern" do
    test "creates message reaction from discord struct with unicode emoji" do
      reaction_struct =
        message_reaction(%{
          emoji: %{id: nil, name: "👍", animated: false},
          count: 5,
          me: false,
          user_id: 123_456_789,
          message_id: 555_666_777,
          channel_id: 111_222_333,
          guild_id: 777_888_999
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: reaction_struct})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_id == nil
      assert created_reaction.emoji_name == "👍"
      assert created_reaction.emoji_animated == false
      assert created_reaction.count == reaction_struct.count
      assert created_reaction.me == false
      assert created_reaction.user_id == reaction_struct.user_id
      assert created_reaction.message_id == reaction_struct.message_id
      assert created_reaction.channel_id == reaction_struct.channel_id
      assert created_reaction.guild_id == reaction_struct.guild_id
    end

    test "creates message reaction with custom emoji" do
      reaction_struct =
        message_reaction(%{
          emoji: %{id: 987_654_321, name: "custom_emoji", animated: false},
          count: 3,
          me: true,
          user_id: 111_222_333,
          message_id: 444_555_666,
          channel_id: 777_888_999,
          guild_id: 333_444_555
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: reaction_struct})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_id == 987_654_321
      assert created_reaction.emoji_name == "custom_emoji"
      assert created_reaction.emoji_animated == false
      assert created_reaction.count == 3
      assert created_reaction.me == true
    end

    test "creates message reaction with animated custom emoji" do
      reaction_struct =
        message_reaction(%{
          emoji: %{id: 555_666_777, name: "animated_party", animated: true},
          count: 12,
          me: false,
          user_id: 777_888_999,
          message_id: 111_222_333,
          channel_id: 444_555_666,
          guild_id: 999_111_222
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: reaction_struct})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_id == 555_666_777
      assert created_reaction.emoji_name == "animated_party"
      assert created_reaction.emoji_animated == true
      assert created_reaction.count == 12
    end

    test "handles single count reaction" do
      reaction_struct =
        message_reaction(%{
          emoji: %{id: nil, name: "❤️", animated: false},
          count: 1,
          me: true,
          user_id: 333_444_555,
          message_id: 666_777_888,
          channel_id: 999_111_222,
          guild_id: 222_333_444
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: reaction_struct})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_name == "❤️"
      assert created_reaction.count == 1
      assert created_reaction.me == true
    end

    test "handles high count reaction" do
      reaction_struct =
        message_reaction(%{
          emoji: %{id: nil, name: "🔥", animated: false},
          count: 999,
          me: false,
          user_id: 888_999_111,
          message_id: 222_333_444,
          channel_id: 555_666_777,
          guild_id: 111_222_333
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: reaction_struct})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_name == "🔥"
      assert created_reaction.count == 999
    end

    test "handles DM reaction without guild_id" do
      reaction_struct =
        message_reaction(%{
          emoji: %{id: nil, name: "😊", animated: false},
          count: 2,
          me: true,
          user_id: 444_555_666,
          message_id: 777_888_999,
          channel_id: 111_222_333,
          # No guild for DM
          guild_id: nil
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: reaction_struct})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_name == "😊"
      assert created_reaction.guild_id == nil
    end
  end

  describe "API fallback pattern" do

    test "message reaction API fallback is not supported" do
      # Message reactions don't support direct API fetching in our implementation
      discord_id = 999_888_777

      result = TestApp.Discord.message_reaction_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      assert error.message =~ "Failed to fetch message_reaction with ID #{discord_id}"
      assert error.message =~ ":unsupported_type"
    end

    test "requires discord_struct for message reaction creation" do
      result = TestApp.Discord.message_reaction_from_discord(%{})

      assert {:error, error} = result
      assert error.message =~ "No Discord ID found for message_reaction entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing message reaction instead of creating duplicate" do
      user_id = 555_666_777
      message_id = 111_222_333
      emoji_name = "👍"

      # Create initial reaction
      initial_struct =
        message_reaction(%{
          emoji: %{id: nil, name: emoji_name, animated: false},
          count: 1,
          me: false,
          user_id: user_id,
          message_id: message_id,
          channel_id: 444_555_666,
          guild_id: 777_888_999
        })

      {:ok, original_reaction} =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: initial_struct})

      # Update same reaction with new count
      updated_struct =
        message_reaction(%{
          emoji: %{id: nil, name: emoji_name, animated: false},
          count: 5,
          me: true,
          user_id: user_id,
          message_id: message_id,
          channel_id: 444_555_666,
          guild_id: 777_888_999
        })

      {:ok, updated_reaction} =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_reaction.id == original_reaction.id
      assert updated_reaction.user_id == original_reaction.user_id
      assert updated_reaction.message_id == original_reaction.message_id
      assert updated_reaction.emoji_name == original_reaction.emoji_name

      # But with updated attributes
      assert updated_reaction.count == 5
      assert updated_reaction.me == true

      # Verify only one reaction record exists for this combination
      all_reactions = TestApp.Discord.MessageReaction.read!()

      reactions_with_combination =
        Enum.filter(
          all_reactions,
          &(&1.user_id == user_id and &1.message_id == message_id and
              &1.emoji_name == emoji_name)
        )

      assert length(reactions_with_combination) == 1
    end

    test "upsert works with custom emoji reactions" do
      user_id = 333_444_555
      message_id = 777_888_999
      emoji_id = 123_456_789

      # Create initial custom emoji reaction
      initial_struct =
        message_reaction(%{
          emoji: %{id: emoji_id, name: "custom_emoji", animated: false},
          count: 2,
          me: false,
          user_id: user_id,
          message_id: message_id,
          channel_id: 999_111_222,
          guild_id: 222_333_444
        })

      {:ok, original_reaction} =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: initial_struct})

      # Update to animated version
      updated_struct =
        message_reaction(%{
          emoji: %{id: emoji_id, name: "custom_emoji", animated: true},
          count: 3,
          me: true,
          user_id: user_id,
          message_id: message_id,
          channel_id: 999_111_222,
          guild_id: 222_333_444
        })

      {:ok, updated_reaction} =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: updated_struct})

      # Should be same record
      assert updated_reaction.id == original_reaction.id
      assert updated_reaction.user_id == user_id
      assert updated_reaction.message_id == message_id
      assert updated_reaction.emoji_id == emoji_id

      # But with updated attributes
      assert updated_reaction.emoji_animated == true
      assert updated_reaction.count == 3
      assert updated_reaction.me == true

      # Verify only one reaction record exists
      all_reactions = TestApp.Discord.MessageReaction.read!()

      reactions_with_combination =
        Enum.filter(
          all_reactions,
          &(&1.user_id == user_id and &1.message_id == message_id and &1.emoji_id == emoji_id)
        )

      assert length(reactions_with_combination) == 1
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.message_reaction_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = %{}

      result = TestApp.Discord.message_reaction_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles missing emoji in discord_struct" do
      invalid_struct = %{
        # Missing emoji field
        count: 1,
        me: false,
        user_id: 123_456_789,
        message_id: 555_666_777
      }

      result = TestApp.Discord.message_reaction_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required" or error_message =~ "emoji"
    end

    test "handles invalid count in discord_struct" do
      reaction_struct =
        message_reaction(%{
          emoji: %{id: nil, name: "👍", animated: false},
          # Invalid count type
          count: "not_an_integer",
          me: false,
          user_id: 123_456_789,
          message_id: 555_666_777,
          channel_id: 111_222_333
        })

      result =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: reaction_struct})

      # This might succeed with normalized count or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_reaction} ->
          # If it succeeds, count should be handled gracefully
          assert created_reaction.emoji_name == "👍"

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end

    test "handles malformed emoji structure" do
      malformed_struct = %{
        # Malformed emoji
        emoji: "not_a_map",
        count: 1,
        me: false,
        user_id: 123_456_789,
        message_id: 555_666_777
      }

      result =
        TestApp.Discord.message_reaction_from_discord(%{discord_struct: malformed_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # Should contain validation errors
      assert error_message =~ "invalid" or error_message =~ "must be"
    end
  end
end
