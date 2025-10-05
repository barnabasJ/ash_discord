defmodule AshDiscord.Changes.FromDiscord.GuildAuditLogEntryTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Consumer.Payloads

  describe "change/3" do
    test "transforms audit log entry event data to resource attributes" do
      entry_id = generate_snowflake()
      user_id = generate_snowflake()
      target_id = to_string(generate_snowflake())

      audit_log_entry_event = %Payloads.GuildAuditLogEntryCreateEvent{
        id: entry_id,
        action_type: 1,
        changes: [%{"key" => "name", "old_value" => "old", "new_value" => "new"}],
        options: %{"count" => "1"},
        reason: "Test reason",
        target_id: target_id,
        user_id: user_id
      }

      {:ok, entry} =
        TestApp.Discord.GuildAuditLogEntry
        |> Ash.Changeset.for_create(:from_discord, %{data: audit_log_entry_event})
        |> Ash.create()

      assert entry.discord_id == entry_id
      assert entry.action_type == 1
      assert entry.changes == [%{"key" => "name", "old_value" => "old", "new_value" => "new"}]
      assert entry.options == %{"count" => "1"}
      assert entry.reason == "Test reason"
      assert entry.target_id == target_id
      assert entry.user_id == user_id
    end

    test "handles audit log entry with minimal fields" do
      entry_id = generate_snowflake()

      audit_log_entry_event = %Payloads.GuildAuditLogEntryCreateEvent{
        id: entry_id,
        action_type: 20,
        changes: nil,
        options: nil,
        reason: nil,
        target_id: nil,
        user_id: nil
      }

      {:ok, entry} =
        TestApp.Discord.GuildAuditLogEntry
        |> Ash.Changeset.for_create(:from_discord, %{data: audit_log_entry_event})
        |> Ash.create()

      assert entry.discord_id == entry_id
      assert entry.action_type == 20
      assert is_nil(entry.changes)
      assert is_nil(entry.options)
      assert is_nil(entry.reason)
      assert is_nil(entry.target_id)
      assert is_nil(entry.user_id)
    end

    test "handles audit log entry with complex changes" do
      entry_id = generate_snowflake()
      user_id = generate_snowflake()

      complex_changes = [
        %{"key" => "name", "old_value" => "old_name", "new_value" => "new_name"},
        %{"key" => "permissions", "old_value" => "0", "new_value" => "8"}
      ]

      audit_log_entry_event = %Payloads.GuildAuditLogEntryCreateEvent{
        id: entry_id,
        action_type: 10,
        changes: complex_changes,
        options: nil,
        reason: "Multiple changes",
        target_id: nil,
        user_id: user_id
      }

      {:ok, entry} =
        TestApp.Discord.GuildAuditLogEntry
        |> Ash.Changeset.for_create(:from_discord, %{data: audit_log_entry_event})
        |> Ash.create()

      assert entry.discord_id == entry_id
      assert entry.action_type == 10
      assert entry.changes == complex_changes
      assert entry.reason == "Multiple changes"
    end

    test "returns error when data argument is missing" do
      changeset =
        TestApp.Discord.GuildAuditLogEntry
        |> Ash.Changeset.for_create(:from_discord, %{})

      assert {:error, %Ash.Error.Invalid{errors: errors}} = Ash.create(changeset)
      assert Enum.any?(errors, &match?(%Ash.Error.Changes.Required{field: :data}, &1))
    end

    test "upserts based on discord_id identity" do
      entry_id = generate_snowflake()

      # Create first version
      first_event = %Payloads.GuildAuditLogEntryCreateEvent{
        id: entry_id,
        action_type: 1,
        changes: nil,
        options: nil,
        reason: "First reason",
        target_id: nil,
        user_id: nil
      }

      {:ok, first_entry} =
        TestApp.Discord.GuildAuditLogEntry
        |> Ash.Changeset.for_create(:from_discord, %{data: first_event})
        |> Ash.create()

      # Upsert with same discord_id but different reason
      second_event = %Payloads.GuildAuditLogEntryCreateEvent{
        id: entry_id,
        action_type: 1,
        changes: nil,
        options: nil,
        reason: "Updated reason",
        target_id: nil,
        user_id: nil
      }

      {:ok, second_entry} =
        TestApp.Discord.GuildAuditLogEntry
        |> Ash.Changeset.for_create(:from_discord, %{data: second_event})
        |> Ash.create()

      # Should have same primary key (upserted)
      assert first_entry.id == second_entry.id
      assert second_entry.reason == "Updated reason"

      # Verify only one record exists
      entries = TestApp.Discord.GuildAuditLogEntry.read!()
      assert length(entries) == 1
    end
  end
end
