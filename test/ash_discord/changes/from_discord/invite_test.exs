defmodule AshDiscord.Changes.FromDiscord.InviteTest do
  @moduledoc """
  Comprehensive tests for Invite entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord
  import Mimic

  setup do
    copy(Nostrum.Api)
    copy(Nostrum.Api.Channel)
    copy(Nostrum.Api.Guild)
    copy(Nostrum.Api.User)

    # Use stub instead of expect for multiple API calls
    stub(Nostrum.Api.Channel, :get, fn channel_id ->
      {:ok, channel(%{id: channel_id, name: "test_channel_#{channel_id}", type: 0})}
    end)

    stub(Nostrum.Api.Guild, :get, fn guild_id ->
      {:ok, guild(%{id: guild_id, name: "Test Guild #{guild_id}"})}
    end)

    stub(Nostrum.Api.User, :get, fn user_id ->
      {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
    end)

    :ok
  end

  describe "struct-first pattern" do
    test "creates invite from discord struct with all attributes" do
      invite_struct =
        invite(%{
          code: "abc123def",
          guild: guild(%{id: 555_666_777}),
          channel: channel(%{id: 111_222_333}),
          inviter: user(%{id: 987_654_321}),
          target_user_type: nil,
          target_user: nil,
          uses: 5,
          max_uses: 10,
          max_age: 3600,
          temporary: false,
          created_at: "2023-01-15T10:30:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{data: invite_struct})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_struct.code
      assert created_invite.guild_discord_id == invite_struct.guild.id
      assert created_invite.channel_discord_id == invite_struct.channel.id
      assert created_invite.inviter_discord_id == invite_struct.inviter.id
      assert created_invite.target_user_type == nil
      assert created_invite.target_user_discord_id == nil
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
          guild: guild(%{id: 777_888_999}),
          channel: channel(%{id: 333_444_555}),
          inviter: user(%{id: 111_222_333}),
          target_user_type: nil,
          target_user: nil,
          uses: 0,
          # No max uses (permanent)
          max_uses: 0,
          # No max age (permanent)
          max_age: 0,
          temporary: false,
          created_at: "2023-02-01T12:00:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{data: invite_struct})

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
          guild: guild(%{id: 999_111_222}),
          channel: channel(%{id: 444_555_666}),
          inviter: user(%{id: 777_888_999}),
          target_user_type: nil,
          target_user: nil,
          uses: 1,
          max_uses: 1,
          max_age: 1800,
          temporary: true,
          created_at: "2023-03-10T15:30:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{data: invite_struct})

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
          guild: guild(%{id: 333_444_555}),
          channel: channel(%{id: 666_777_888}),
          inviter: user(%{id: 999_111_222}),
          # Stream target type
          target_user_type: 1,
          target_user: user(%{id: 123_456_789}),
          uses: 0,
          max_uses: 5,
          max_age: 3600,
          temporary: false,
          created_at: "2023-04-05T09:00:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{data: invite_struct})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_struct.code
      assert created_invite.target_user_type == 1
      assert created_invite.target_user_discord_id == 123_456_789
    end

    test "handles embedded application target invite" do
      invite_struct =
        invite(%{
          code: "app012jkl",
          guild: guild(%{id: 777_888_999}),
          channel: channel(%{id: 111_222_333}),
          inviter: user(%{id: 444_555_666}),
          # Embedded application target type
          target_user_type: 2,
          target_user: nil,
          uses: 3,
          max_uses: 10,
          max_age: 7200,
          temporary: false,
          created_at: "2023-05-12T14:20:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{data: invite_struct})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_struct.code
      assert created_invite.target_user_type == 2
      assert created_invite.target_user_discord_id == nil
    end

    test "handles invite without inviter" do
      invite_struct =
        invite(%{
          code: "noinviter345",
          guild: guild(%{id: 555_666_777}),
          channel: channel(%{id: 888_999_111}),
          # No inviter (vanity URL or widget)
          inviter: nil,
          target_user_type: nil,
          target_user: nil,
          uses: 50,
          max_uses: 0,
          max_age: 0,
          temporary: false,
          created_at: "2023-06-01T18:45:00Z"
        })

      result = TestApp.Discord.invite_from_discord(%{data: invite_struct})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_struct.code
      assert created_invite.inviter_discord_id == nil
    end
  end

  describe "API fallback pattern" do
    test "fetches invite from API when data not provided" do
      invite_code = "abc123def"

      expect(Nostrum.Api, :get_invite, fn ^invite_code ->
        {:ok,
         invite(%{
           code: invite_code,
           guild: guild(%{id: 555_666_777}),
           channel: channel(%{id: 111_222_333}),
           inviter: user(%{id: 987_654_321}),
           uses: 10,
           max_uses: 100,
           max_age: 7200,
           temporary: false,
           created_at: "2023-08-15T14:30:00Z"
         })}
      end)

      result = TestApp.Discord.invite_from_discord(%{identity: invite_code})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_code
      assert created_invite.guild_discord_id == 555_666_777
      assert created_invite.channel_discord_id == 111_222_333
      assert created_invite.inviter_discord_id == 987_654_321
      assert created_invite.uses == 10
      assert created_invite.max_uses == 100
    end

    test "handles API errors gracefully" do
      invite_code = "notfound404"

      expect(Nostrum.Api, :get_invite, fn ^invite_code ->
        {:error, %{status_code: 404, message: "Unknown Invite"}}
      end)

      result = TestApp.Discord.invite_from_discord(%{identity: invite_code})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Unknown Invite" or error_message =~ "404"
    end

    test "requires data or identity argument for invite creation" do
      result = TestApp.Discord.invite_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Identity must be a string invite code"
    end
  end

  describe "upsert behavior" do
    test "updates existing invite instead of creating duplicate" do
      code = "upsert123"

      # Create initial invite
      initial_struct =
        invite(%{
          code: code,
          guild: guild(%{id: 555_666_777}),
          channel: channel(%{id: 111_222_333}),
          inviter: user(%{id: 987_654_321}),
          uses: 0,
          max_uses: 5,
          max_age: 3600,
          temporary: false,
          created_at: "2023-01-01T00:00:00Z"
        })

      {:ok, original_invite} =
        TestApp.Discord.invite_from_discord(%{data: initial_struct})

      # Update same invite with new usage data
      updated_struct =
        invite(%{
          # Same code
          code: code,
          guild: guild(%{id: 555_666_777}),
          channel: channel(%{id: 111_222_333}),
          inviter: user(%{id: 987_654_321}),
          uses: 3,
          max_uses: 5,
          max_age: 3600,
          temporary: false,
          created_at: "2023-01-01T00:00:00Z"
        })

      {:ok, updated_invite} =
        TestApp.Discord.invite_from_discord(%{data: updated_struct})

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
          guild: guild(%{id: 777_888_999}),
          channel: channel(%{id: 333_444_555}),
          inviter: user(%{id: 111_222_333}),
          uses: 0,
          max_uses: 1,
          max_age: 1800,
          temporary: true,
          created_at: "2023-07-01T10:00:00Z"
        })

      {:ok, original_invite} =
        TestApp.Discord.invite_from_discord(%{data: initial_struct})

      # Update to permanent invite
      updated_struct =
        invite(%{
          # Same code
          code: code,
          guild: guild(%{id: 777_888_999}),
          channel: channel(%{id: 333_444_555}),
          inviter: user(%{id: 111_222_333}),
          uses: 0,
          max_uses: 0,
          max_age: 0,
          temporary: false,
          created_at: "2023-07-01T10:00:00Z"
        })

      {:ok, updated_invite} =
        TestApp.Discord.invite_from_discord(%{data: updated_struct})

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
    test "handles invalid data argument format" do
      result = TestApp.Discord.invite_from_discord(%{data: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for data"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields - code is required for invites
      invalid_struct = invite(%{code: nil})

      result = TestApp.Discord.invite_from_discord(%{data: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required" or error_message =~ "must not be nil"
    end

    test "handles invalid created_at format" do
      invite_struct =
        invite(%{
          code: "invalid789",
          guild: guild(%{id: 555_666_777}),
          channel: channel(%{id: 111_222_333}),
          inviter: user(%{id: 987_654_321}),
          uses: 0,
          max_uses: 1,
          max_age: 3600,
          temporary: false,
          # Invalid datetime format
          created_at: "not_a_datetime"
        })

      result = TestApp.Discord.invite_from_discord(%{data: invite_struct})

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
        guild: "not_a_struct",
        uses: "not_an_integer"
      }

      result = TestApp.Discord.invite_from_discord(%{data: malformed_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # Should contain validation errors - payload validation catches this
      assert error_message =~ "is required" or error_message =~ "is invalid" or
               error_message =~ "no function clause"
    end
  end
end
