defmodule AshDiscord.Changes.FromDiscord.GuildMemberTest do
  @moduledoc """
  Comprehensive tests for GuildMember entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord



  describe "struct-first pattern" do
    test "creates guild member from discord struct with all attributes" do
      member_struct =
        guild_member(%{
          user: user(%{id: 123_456_789, username: "test_user"}),
          nick: "TestNick",
          joined_at: "2023-01-15T10:30:00Z",
          deaf: false,
          mute: false,
          guild_id: 555_666_777
        })

      result = TestApp.Discord.guild_member_from_discord(%{discord_struct: member_struct})

      assert {:ok, created_member} = result
      assert created_member.user_id == member_struct.user.id
      assert created_member.nick == member_struct.nick
      assert created_member.joined_at == ~U[2023-01-15 10:30:00Z]
      assert created_member.deaf == false
      assert created_member.mute == false
      assert created_member.guild_id == member_struct.guild_id
    end

    test "handles member without nickname" do
      member_struct =
        guild_member(%{
          user: user(%{id: 987_654_321, username: "no_nick_user"}),
          nick: nil,
          joined_at: "2023-02-20T15:45:00Z",
          deaf: false,
          mute: false
        })

      result = TestApp.Discord.guild_member_from_discord(%{discord_struct: member_struct})

      assert {:ok, created_member} = result
      assert created_member.user_id == member_struct.user.id
      assert created_member.nick == nil
      assert created_member.joined_at == ~U[2023-02-20 15:45:00Z]
    end

    test "handles deafened member" do
      member_struct =
        guild_member(%{
          user: user(%{id: 111_222_333, username: "deaf_user"}),
          nick: "DeafUser",
          joined_at: "2023-03-10T08:15:00Z",
          deaf: true,
          mute: false
        })

      result = TestApp.Discord.guild_member_from_discord(%{discord_struct: member_struct})

      assert {:ok, created_member} = result
      assert created_member.user_id == member_struct.user.id
      assert created_member.deaf == true
      assert created_member.mute == false
    end

    test "handles muted member" do
      member_struct =
        guild_member(%{
          user: user(%{id: 777_888_999, username: "mute_user"}),
          nick: "MuteUser",
          joined_at: "2023-04-05T12:00:00Z",
          deaf: false,
          mute: true
        })

      result = TestApp.Discord.guild_member_from_discord(%{discord_struct: member_struct})

      assert {:ok, created_member} = result
      assert created_member.user_id == member_struct.user.id
      assert created_member.deaf == false
      assert created_member.mute == true
    end

    test "handles member with both deaf and mute" do
      member_struct =
        guild_member(%{
          user: user(%{id: 333_444_555, username: "silent_user"}),
          nick: "SilentUser",
          joined_at: "2023-05-12T18:30:00Z",
          deaf: true,
          mute: true
        })

      result = TestApp.Discord.guild_member_from_discord(%{discord_struct: member_struct})

      assert {:ok, created_member} = result
      assert created_member.user_id == member_struct.user.id
      assert created_member.deaf == true
      assert created_member.mute == true
    end
  end

  describe "API fallback pattern" do

    test "guild member API fallback is not supported" do
      # Guild members don't support direct API fetching in our implementation
      discord_id = 999_888_777

      result = TestApp.Discord.guild_member_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Failed to fetch guild_member with ID #{discord_id}"
      error_message = Exception.message(error)
      assert error_message =~ ":unsupported_type"
    end

    test "requires discord_struct for guild member creation" do
      result = TestApp.Discord.guild_member_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord ID found for guild_member entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing guild member instead of creating duplicate" do
      user_id = 555_666_777
      guild_id = 111_222_333

      # Create initial member
      initial_struct =
        guild_member(%{
          user: user(%{id: user_id, username: "original_user"}),
          nick: "OriginalNick",
          joined_at: "2023-01-01T00:00:00Z",
          deaf: false,
          mute: false,
          guild_id: guild_id
        })

      {:ok, original_member} =
        TestApp.Discord.guild_member_from_discord(%{discord_struct: initial_struct})

      # Update same member with new data
      updated_struct =
        guild_member(%{
          user: user(%{id: user_id, username: "original_user"}),
          nick: "UpdatedNick",
          joined_at: "2023-01-01T00:00:00Z",
          deaf: true,
          mute: true,
          guild_id: guild_id
        })

      {:ok, updated_member} =
        TestApp.Discord.guild_member_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_member.id == original_member.id
      assert updated_member.user_id == original_member.user_id
      assert updated_member.guild_id == original_member.guild_id

      # But with updated attributes
      assert updated_member.nick == "UpdatedNick"
      assert updated_member.deaf == true
      assert updated_member.mute == true

    end

    test "upsert works with nickname changes" do
      user_id = 333_444_555
      guild_id = 777_888_999

      # Create initial member with nickname
      initial_struct =
        guild_member(%{
          user: user(%{id: user_id, username: "nick_user"}),
          nick: "OldNick",
          joined_at: "2023-06-01T12:00:00Z",
          deaf: false,
          mute: false,
          guild_id: guild_id
        })

      {:ok, original_member} =
        TestApp.Discord.guild_member_from_discord(%{discord_struct: initial_struct})

      # Remove nickname
      updated_struct =
        guild_member(%{
          user: user(%{id: user_id, username: "nick_user"}),
          nick: nil,
          joined_at: "2023-06-01T12:00:00Z",
          deaf: false,
          mute: false,
          guild_id: guild_id
        })

      {:ok, updated_member} =
        TestApp.Discord.guild_member_from_discord(%{discord_struct: updated_struct})

      # Should be same record
      assert updated_member.id == original_member.id
      assert updated_member.user_id == user_id
      assert updated_member.guild_id == guild_id

      # But with removed nickname
      assert updated_member.nick == nil

    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.guild_member_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = guild_member(%{id: nil, name: nil})

      result = TestApp.Discord.guild_member_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles invalid joined_at format" do
      member_struct =
        guild_member(%{
          user: user(%{id: 123_456_789, username: "test_user"}),
          nick: "TestUser",
          # Invalid datetime format
          joined_at: "not_a_datetime",
          deaf: false,
          mute: false
        })

      result = TestApp.Discord.guild_member_from_discord(%{discord_struct: member_struct})

      # This might succeed with nil joined_at or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_member} ->
          # If it succeeds, joined_at should be handled gracefully
          assert created_member.user_id == member_struct.user.id

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end

    test "handles missing user in discord_struct" do
      invalid_struct = %{
        # Missing user field
        nick: "TestNick",
        joined_at: "2023-01-01T00:00:00Z"
      }

      result = TestApp.Discord.guild_member_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required" or error_message =~ "user"
    end
  end
end
