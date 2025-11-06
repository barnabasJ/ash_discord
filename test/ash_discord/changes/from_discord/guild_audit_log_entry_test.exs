defmodule AshDiscord.Changes.FromDiscord.GuildAuditLogEntryTest do
  @moduledoc """
  Comprehensive tests for GuildAuditLogEntry entity from_discord transformation.

  Tests struct-first pattern and upsert behavior. No API fallback pattern since
  individual audit log entries cannot be fetched by ID from Discord API.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates audit log entry from discord struct with all attributes" do
      user_id = 555_666_777

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      entry_struct =
        guild_audit_log_entry(%{
          id: 123_456_789,
          action_type: 1,
          changes: [%{"key" => "name", "old_value" => "old", "new_value" => "new"}],
          options: %{"count" => "1"},
          reason: "Test reason",
          target_id: "999_888_777",
          user_id: user_id
        })

      created =
        TestApp.Discord.guild_audit_log_entry_from_discord!(%{data: entry_struct}, load: [:user])

      assert created.discord_id == entry_struct.id
      assert created.action_type == entry_struct.action_type
      assert created.changes == entry_struct.changes
      assert created.options == entry_struct.options
      assert created.reason == entry_struct.reason
      assert created.target_discord_id == entry_struct.target_id
      assert created.user.discord_id == user_id
    end

    @tag :fixed
    test "handles audit log entry with minimal fields" do
      entry_struct =
        guild_audit_log_entry(%{
          id: 987_654_321,
          action_type: 20,
          changes: nil,
          options: nil,
          reason: nil,
          target_id: nil,
          user_id: nil
        })

      created = TestApp.Discord.guild_audit_log_entry_from_discord!(%{data: entry_struct})

      assert created.discord_id == entry_struct.id
      assert created.action_type == entry_struct.action_type
      assert is_nil(created.changes)
      assert is_nil(created.options)
      assert is_nil(created.reason)
      assert is_nil(created.target_discord_id)
      assert is_nil(created.user_discord_id)
    end

    @tag :fixed
    test "handles audit log entry with complex changes" do
      user_id = 111_222_333

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      complex_changes = [
        %{"key" => "name", "old_value" => "old_name", "new_value" => "new_name"},
        %{"key" => "permissions", "old_value" => "0", "new_value" => "8"}
      ]

      entry_struct =
        guild_audit_log_entry(%{
          id: 444_555_666,
          action_type: 10,
          changes: complex_changes,
          options: nil,
          reason: "Multiple changes",
          target_id: nil,
          user_id: user_id
        })

      created =
        TestApp.Discord.guild_audit_log_entry_from_discord!(%{data: entry_struct}, load: [:user])

      assert created.discord_id == entry_struct.id
      assert created.action_type == entry_struct.action_type
      assert created.changes == complex_changes
      assert created.reason == entry_struct.reason
      assert created.user.discord_id == user_id
    end

    @tag :fixed
    test "handles audit log entry with complex options" do
      user_id = 777_888_999

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      complex_options = %{
        "delete_member_days" => "7",
        "members_removed" => "5"
      }

      entry_struct =
        guild_audit_log_entry(%{
          id: 333_444_555,
          action_type: 21,
          changes: nil,
          options: complex_options,
          reason: "Cleanup",
          target_id: "123_456_789",
          user_id: user_id
        })

      created =
        TestApp.Discord.guild_audit_log_entry_from_discord!(%{data: entry_struct}, load: [:user])

      assert created.discord_id == entry_struct.id
      assert created.options == complex_options
      assert created.target_discord_id == "123_456_789"
      assert created.user.discord_id == user_id
    end

    @tag :fixed
    test "handles audit log entry without user" do
      entry_struct =
        guild_audit_log_entry(%{
          id: 222_333_444,
          action_type: 15,
          changes: [%{"key" => "status", "new_value" => "active"}],
          options: nil,
          reason: "System action",
          target_id: "555_666_777",
          user_id: nil
        })

      created = TestApp.Discord.guild_audit_log_entry_from_discord!(%{data: entry_struct})

      assert created.discord_id == entry_struct.id
      assert created.action_type == entry_struct.action_type
      assert created.target_discord_id == "555_666_777"
      assert is_nil(created.user_discord_id)
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing audit log entry instead of creating duplicate" do
      user_id = 888_999_000

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      entry_id = 666_777_888

      initial_struct =
        guild_audit_log_entry(%{
          id: entry_id,
          action_type: 1,
          changes: nil,
          options: nil,
          reason: "Original reason",
          target_id: nil,
          user_id: user_id
        })

      original =
        TestApp.Discord.guild_audit_log_entry_from_discord!(%{data: initial_struct},
          load: [:user]
        )

      updated_struct =
        guild_audit_log_entry(%{
          id: entry_id,
          action_type: 1,
          changes: [%{"key" => "updated", "new_value" => "yes"}],
          options: %{"new_option" => "value"},
          reason: "Updated reason",
          target_id: "123_456",
          user_id: user_id
        })

      updated =
        TestApp.Discord.guild_audit_log_entry_from_discord!(%{data: updated_struct},
          load: [:user]
        )

      assert updated.id == original.id
      assert updated.discord_id == original.discord_id

      assert updated.reason == "Updated reason"
      assert updated.changes == [%{"key" => "updated", "new_value" => "yes"}]
      assert updated.options == %{"new_option" => "value"}
      assert updated.target_discord_id == "123_456"
      assert updated.user.discord_id == user_id
    end

    @tag :fixed
    test "updates audit log entry from minimal to full attributes" do
      user_id = 100_200_300

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      entry_id = 400_500_600

      minimal_struct =
        guild_audit_log_entry(%{
          id: entry_id,
          action_type: 5,
          changes: nil,
          options: nil,
          reason: nil,
          target_id: nil,
          user_id: nil
        })

      original = TestApp.Discord.guild_audit_log_entry_from_discord!(%{data: minimal_struct})

      full_struct =
        guild_audit_log_entry(%{
          id: entry_id,
          action_type: 5,
          changes: [%{"key" => "added", "new_value" => "data"}],
          options: %{"filled" => "true"},
          reason: "Now has reason",
          target_id: "789_012",
          user_id: user_id
        })

      updated =
        TestApp.Discord.guild_audit_log_entry_from_discord!(%{data: full_struct}, load: [:user])

      assert updated.id == original.id
      assert updated.discord_id == original.discord_id

      assert updated.changes == [%{"key" => "added", "new_value" => "data"}]
      assert updated.options == %{"filled" => "true"}
      assert updated.reason == "Now has reason"
      assert updated.target_discord_id == "789_012"
      assert updated.user.discord_id == user_id
    end
  end
end
