defmodule AshDiscord.Consumer.Handler.Guild.Audit.Log.EntryTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Consumer.Handler.Guild.Audit.Log.Entry
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    test "creates audit log entry record in database" do
      entry_id = generate_snowflake()
      user_id = generate_snowflake()
      target_id = to_string(generate_snowflake())

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil
      }

      audit_log_entry_event = %Payloads.GuildAuditLogEntryCreateEvent{
        id: entry_id,
        action_type: 1,
        changes: [%{"key" => "name", "old_value" => "old", "new_value" => "new"}],
        options: %{"count" => "1"},
        reason: "Test reason",
        target_id: target_id,
        user_id: user_id
      }

      assert :ok =
               Entry.create(
                 audit_log_entry_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify entry was created in database
      entries = TestApp.Discord.GuildAuditLogEntry.read!()
      assert length(entries) == 1

      created_entry = hd(entries)
      assert created_entry.discord_id == entry_id
      assert created_entry.action_type == 1

      assert created_entry.changes == [
               %{"key" => "name", "old_value" => "old", "new_value" => "new"}
             ]

      assert created_entry.options == %{"count" => "1"}
      assert created_entry.reason == "Test reason"
      assert created_entry.target_id == target_id
      assert created_entry.user_id == user_id
    end

    test "upserts audit log entry if already exists" do
      entry_id = generate_snowflake()
      user_id = generate_snowflake()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil
      }

      audit_log_entry_event = %Payloads.GuildAuditLogEntryCreateEvent{
        id: entry_id,
        action_type: 1,
        changes: nil,
        options: nil,
        reason: "First reason",
        target_id: nil,
        user_id: user_id
      }

      # Create entry first time
      assert :ok =
               Entry.create(
                 audit_log_entry_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Update with new reason (should upsert)
      updated_event = %{audit_log_entry_event | reason: "Updated reason"}

      assert :ok =
               Entry.create(
                 updated_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify only one entry exists with updated reason
      entries = TestApp.Discord.GuildAuditLogEntry.read!()
      assert length(entries) == 1
      updated_entry = hd(entries)
      assert updated_entry.reason == "Updated reason"
    end

    test "handles audit log entry with minimal fields" do
      entry_id = generate_snowflake()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil
      }

      audit_log_entry_event = %Payloads.GuildAuditLogEntryCreateEvent{
        id: entry_id,
        action_type: 1,
        changes: nil,
        options: nil,
        reason: nil,
        target_id: nil,
        user_id: nil
      }

      assert :ok =
               Entry.create(
                 audit_log_entry_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify entry was created with minimal fields
      entries = TestApp.Discord.GuildAuditLogEntry.read!()
      assert length(entries) == 1

      created_entry = hd(entries)
      assert created_entry.discord_id == entry_id
      assert created_entry.action_type == 1
      assert is_nil(created_entry.changes)
      assert is_nil(created_entry.options)
      assert is_nil(created_entry.reason)
      assert is_nil(created_entry.target_id)
      assert is_nil(created_entry.user_id)
    end

    test "handles different action types" do
      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil
      }

      # Create entries with different action types
      action_types = [1, 10, 20, 72]

      for action_type <- action_types do
        entry_id = generate_snowflake()

        audit_log_entry_event = %Payloads.GuildAuditLogEntryCreateEvent{
          id: entry_id,
          action_type: action_type,
          changes: nil,
          options: nil,
          reason: nil,
          target_id: nil,
          user_id: nil
        }

        assert :ok =
                 Entry.create(
                   audit_log_entry_event,
                   %Nostrum.Struct.WSState{},
                   context
                 )
      end

      # Verify all entries were created
      entries = TestApp.Discord.GuildAuditLogEntry.read!()
      assert length(entries) == 4

      created_action_types = Enum.map(entries, & &1.action_type) |> Enum.sort()
      assert created_action_types == Enum.sort(action_types)
    end
  end
end
