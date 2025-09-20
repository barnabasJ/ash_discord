defmodule AshDiscord.Changes.FromDiscord.InviteTest do
  @moduledoc """
  Comprehensive tests for Invite entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord



  describe "struct-first pattern" do
    test "creates invite from discord struct with all attributes" do
      invite_struct =
        invite(%{
          code: "abc123def",
          guild_id: 555_666_777,
          channel_id: 111_222_333,
          inviter_id: 987_654_321,
          target_type: nil,
          target_user_id: nil,
          uses: 5,
          max_uses: 10,
          max_age: 3600,
          temporary: false,
          created_at: "2023-01-15T10:30:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{discord_struct: invite_struct})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_struct.code
      assert created_invite.guild_id == invite_struct.guild_id
      assert created_invite.channel_id == invite_struct.channel_id
      assert created_invite.inviter_id == invite_struct.inviter_id
      assert created_invite.target_type == nil
      assert created_invite.target_user_id == nil
      assert created_invite.uses == invite_struct.uses
      assert created_invite.max_uses == invite_struct.max_uses
      assert created_invite.max_age == invite_struct.max_age
      assert created_invite.temporary == false
      assert created_invite.created_at == ~U[2023-01-15 10:30:00Z]
    end

    test "handles permanent invite" do
      invite_struct =
        invite(%{
          code: "permanent123",
          guild_id: 777_888_999,
          channel_id: 333_444_555,
          inviter_id: 111_222_333,
          target_type: nil,
          target_user_id: nil,
          uses: 0,
          # No max uses (permanent)
          max_uses: 0,
          # No max age (permanent)
          max_age: 0,
          temporary: false,
          created_at: "2023-02-01T12:00:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{discord_struct: invite_struct})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_struct.code
      assert created_invite.max_uses == 0
      assert created_invite.max_age == 0
      assert created_invite.temporary == false
    end

    test "handles temporary invite" do
      invite_struct =
        invite(%{
          code: "temp456def",
          guild_id: 999_111_222,
          channel_id: 444_555_666,
          inviter_id: 777_888_999,
          target_type: nil,
          target_user_id: nil,
          uses: 1,
          max_uses: 1,
          max_age: 1800,
          temporary: true,
          created_at: "2023-03-10T15:30:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{discord_struct: invite_struct})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_struct.code
      assert created_invite.temporary == true
      assert created_invite.max_uses == 1
      assert created_invite.max_age == 1800
    end

    test "handles stream target invite" do
      invite_struct =
        invite(%{
          code: "stream789ghi",
          guild_id: 333_444_555,
          channel_id: 666_777_888,
          inviter_id: 999_111_222,
          # Stream target type
          target_type: 1,
          target_user_id: 123_456_789,
          uses: 0,
          max_uses: 5,
          max_age: 3600,
          temporary: false,
          created_at: "2023-04-05T09:00:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{discord_struct: invite_struct})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_struct.code
      assert created_invite.target_type == 1
      assert created_invite.target_user_id == invite_struct.target_user_id
    end

    test "handles embedded application target invite" do
      invite_struct =
        invite(%{
          code: "app012jkl",
          guild_id: 777_888_999,
          channel_id: 111_222_333,
          inviter_id: 444_555_666,
          # Embedded application target type
          target_type: 2,
          target_user_id: nil,
          uses: 3,
          max_uses: 10,
          max_age: 7200,
          temporary: false,
          created_at: "2023-05-12T14:20:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{discord_struct: invite_struct})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_struct.code
      assert created_invite.target_type == 2
      assert created_invite.target_user_id == nil
    end

    test "handles invite without inviter" do
      invite_struct =
        invite(%{
          code: "noinviter345",
          guild_id: 555_666_777,
          channel_id: 888_999_111,
          # No inviter (vanity URL or widget)
          inviter_id: nil,
          target_type: nil,
          target_user_id: nil,
          uses: 50,
          max_uses: 0,
          max_age: 0,
          temporary: false,
          created_at: "2023-06-01T18:45:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{discord_struct: invite_struct})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_struct.code
      assert created_invite.inviter_id == nil
    end
  end

  describe "API fallback pattern" do

    test "invite API fallback is not supported" do
      # Invites don't support direct API fetching in our implementation
      discord_id = "abc123def"

      result = TestApp.Discord.invite_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Failed to fetch invite with ID #{discord_id}"
      error_message = Exception.message(error)
      assert error_message =~ ":unsupported_type"
    end

    test "requires discord_struct for invite creation" do
      result = TestApp.Discord.invite_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord ID found for invite entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing invite instead of creating duplicate" do
      code = "upsert123"

      # Create initial invite
      initial_struct =
        invite(%{
          code: code,
          guild_id: 555_666_777,
          channel_id: 111_222_333,
          inviter_id: 987_654_321,
          uses: 0,
          max_uses: 5,
          max_age: 3600,
          temporary: false,
          created_at: "2023-01-01T00:00:00Z"
        })

      {:ok, original_invite} =
        TestApp.Discord.invite_from_discord(%{discord_struct: initial_struct})

      # Update same invite with new usage data
      updated_struct =
        invite(%{
          # Same code
          code: code,
          guild_id: 555_666_777,
          channel_id: 111_222_333,
          inviter_id: 987_654_321,
          uses: 3,
          max_uses: 5,
          max_age: 3600,
          temporary: false,
          created_at: "2023-01-01T00:00:00Z"
        })

      {:ok, updated_invite} =
        TestApp.Discord.invite_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_invite.id == original_invite.id
      assert updated_invite.code == original_invite.code

      # But with updated attributes
      assert updated_invite.uses == 3

    end

    test "upsert works with usage limit changes" do
      code = "limit456"

      # Create initial invite with usage limit
      initial_struct =
        invite(%{
          code: code,
          guild_id: 777_888_999,
          channel_id: 333_444_555,
          inviter_id: 111_222_333,
          uses: 0,
          max_uses: 1,
          max_age: 1800,
          temporary: true,
          created_at: "2023-07-01T10:00:00Z"
        })

      {:ok, original_invite} =
        TestApp.Discord.invite_from_discord(%{discord_struct: initial_struct})

      # Update to permanent invite
      updated_struct =
        invite(%{
          # Same code
          code: code,
          guild_id: 777_888_999,
          channel_id: 333_444_555,
          inviter_id: 111_222_333,
          uses: 0,
          max_uses: 0,
          max_age: 0,
          temporary: false,
          created_at: "2023-07-01T10:00:00Z"
        })

      {:ok, updated_invite} =
        TestApp.Discord.invite_from_discord(%{discord_struct: updated_struct})

      # Should be same record
      assert updated_invite.id == original_invite.id
      assert updated_invite.code == code

      # But with updated limits
      assert updated_invite.max_uses == 0
      assert updated_invite.max_age == 0
      assert updated_invite.temporary == false

    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.invite_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = %{}

      result = TestApp.Discord.invite_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles invalid created_at format" do
      invite_struct =
        invite(%{
          code: "invalid789",
          guild_id: 555_666_777,
          channel_id: 111_222_333,
          inviter_id: 987_654_321,
          uses: 0,
          max_uses: 1,
          max_age: 3600,
          temporary: false,
          # Invalid datetime format
          created_at: "not_a_datetime"
        })

      result = TestApp.Discord.invite_from_discord(%{discord_struct: invite_struct})

      # This might succeed with nil created_at or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_invite} ->
          # If it succeeds, created_at should be handled gracefully
          assert created_invite.code == invite_struct.code

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end

    test "handles malformed invite data" do
      malformed_struct = %{
        # Required field as nil
        code: nil,
        guild_id: "not_an_integer",
        uses: "not_an_integer"
      }

      result = TestApp.Discord.invite_from_discord(%{discord_struct: malformed_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # Should contain validation errors
      assert error_message =~ "is required" or error_message =~ "is invalid"
    end
  end
end
