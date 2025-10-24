defmodule AshDiscord.Consumer.Handler.GuildAuditLogEntryTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.GuildAuditLogEntry
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    @tag :fixed
    test "creates audit log entry record in database" do
      entry =
        guild_audit_log_entry(%{
          action_type: 1,
          changes: [%{"key" => "name", "old_value" => "old", "new_value" => "new"}],
          options: %{"count" => "1"},
          reason: "Test reason",
          target_id: to_string(generate_snowflake()),
          user_id: generate_snowflake()
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

      assert :ok =
               GuildAuditLogEntry.create(
                 audit_log_entry_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify entry was created in database
      assert [created_entry] = TestApp.Discord.GuildAuditLogEntry.read!()

      assert created_entry.discord_id == entry.id
      assert created_entry.action_type == 1

      assert created_entry.changes == [
               %{"key" => "name", "old_value" => "old", "new_value" => "new"}
             ]

      assert created_entry.options == %{"count" => "1"}
      assert created_entry.reason == "Test reason"
      assert created_entry.target_id == entry.target_id
      assert created_entry.user_id == entry.user_id
    end

    @tag :fixed
    test "upserts audit log entry if already exists" do
      entry =
        guild_audit_log_entry(%{
          action_type: 1,
          changes: nil,
          options: nil,
          reason: "First reason",
          target_id: nil,
          user_id: generate_snowflake()
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

      # Create entry first time
      assert :ok =
               GuildAuditLogEntry.create(
                 audit_log_entry_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Update with new reason (should upsert)
      updated_entry = %{entry | reason: "Updated reason"}
      updated_event = Payloads.GuildAuditLogEntryCreateEvent.new!(updated_entry)

      assert :ok =
               GuildAuditLogEntry.create(
                 updated_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify only one entry exists with updated reason
      assert [updated_record] = TestApp.Discord.GuildAuditLogEntry.read!()
      assert updated_record.reason == "Updated reason"
    end

    @tag :fixed
    test "handles audit log entry with minimal fields" do
      entry =
        guild_audit_log_entry(%{
          action_type: 1,
          changes: nil,
          options: nil,
          reason: nil,
          target_id: nil,
          user_id: nil
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

      assert :ok =
               GuildAuditLogEntry.create(
                 audit_log_entry_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify entry was created with minimal fields
      assert [created_entry] = TestApp.Discord.GuildAuditLogEntry.read!()

      assert created_entry.discord_id == entry.id
      assert created_entry.action_type == 1
      assert is_nil(created_entry.changes)
      assert is_nil(created_entry.options)
      assert is_nil(created_entry.reason)
      assert is_nil(created_entry.target_id)
      assert is_nil(created_entry.user_id)
    end

    @tag :fixed
    test "handles different action types" do
      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      # Create entries with different action types
      action_types = [1, 10, 20, 72]

      for action_type <- action_types do
        entry =
          guild_audit_log_entry(%{
            action_type: action_type,
            changes: nil,
            options: nil,
            reason: nil,
            target_id: nil,
            user_id: nil
          })

        audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

        assert :ok =
                 GuildAuditLogEntry.create(
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

  describe "optional fields" do
    @tag :fixed
    test "handles changes field with complex structures" do
      entry =
        guild_audit_log_entry(%{
          action_type: 11,
          changes: [
            %{"key" => "name", "old_value" => "old-name", "new_value" => "new-name"},
            %{"key" => "topic", "old_value" => "Old topic", "new_value" => "New topic"},
            %{"key" => "nsfw", "old_value" => false, "new_value" => true}
          ],
          options: nil,
          reason: "Channel update",
          target_id: to_string(generate_snowflake()),
          user_id: generate_snowflake()
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

      assert :ok =
               GuildAuditLogEntry.create(
                 audit_log_entry_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      assert [created_entry] = TestApp.Discord.GuildAuditLogEntry.read!()
      assert length(created_entry.changes) == 3
      assert Enum.any?(created_entry.changes, &(&1["key"] == "name"))
      assert Enum.any?(created_entry.changes, &(&1["key"] == "topic"))
      assert Enum.any?(created_entry.changes, &(&1["key"] == "nsfw"))
    end

    @tag :fixed
    test "handles options field with metadata" do
      entry =
        guild_audit_log_entry(%{
          action_type: 72,
          changes: nil,
          options: %{
            "count" => "5",
            "channel_id" => to_string(generate_snowflake()),
            "delete_member_days" => "7"
          },
          reason: "Bulk message delete",
          target_id: to_string(generate_snowflake()),
          user_id: generate_snowflake()
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

      assert :ok =
               GuildAuditLogEntry.create(
                 audit_log_entry_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      assert [created_entry] = TestApp.Discord.GuildAuditLogEntry.read!()
      assert created_entry.options["count"] == "5"
      assert created_entry.options["delete_member_days"] == "7"
      assert is_binary(created_entry.options["channel_id"])
    end

    @tag :fixed
    test "handles reason field with various lengths" do
      short_reason = "Quick fix"
      medium_reason = "Updated channel permissions for better security"

      long_reason =
        "This is a very long reason that explains in great detail why this action was taken. " <>
          "It includes multiple sentences and provides comprehensive context for future reference."

      reasons = [short_reason, medium_reason, long_reason]

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      for reason <- reasons do
        entry =
          guild_audit_log_entry(%{
            action_type: 1,
            changes: nil,
            options: nil,
            reason: reason,
            target_id: nil,
            user_id: generate_snowflake()
          })

        audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

        assert :ok =
                 GuildAuditLogEntry.create(
                   audit_log_entry_event,
                   %Nostrum.Struct.WSState{},
                   context
                 )
      end

      entries = TestApp.Discord.GuildAuditLogEntry.read!()
      assert length(entries) == 3

      saved_reasons = Enum.map(entries, & &1.reason) |> Enum.sort()
      assert saved_reasons == Enum.sort(reasons)
    end
  end

  describe "action type categories" do
    @tag :fixed
    test "handles guild action types (1-2)" do
      entry =
        guild_audit_log_entry(%{
          action_type: 1,
          changes: [%{"key" => "name", "old_value" => "Old Guild", "new_value" => "New Guild"}],
          options: nil,
          reason: "Guild update",
          target_id: to_string(generate_snowflake()),
          user_id: generate_snowflake()
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

      assert :ok =
               GuildAuditLogEntry.create(
                 audit_log_entry_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      assert [created_entry] = TestApp.Discord.GuildAuditLogEntry.read!()
      assert created_entry.action_type == 1
      assert created_entry.reason == "Guild update"
    end

    @tag :fixed
    test "handles channel action types (10-12)" do
      channel_actions = [
        {10, "Channel created"},
        {11, "Channel updated"},
        {12, "Channel deleted"}
      ]

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      for {action_type, reason} <- channel_actions do
        entry =
          guild_audit_log_entry(%{
            action_type: action_type,
            changes: nil,
            options: nil,
            reason: reason,
            target_id: to_string(generate_snowflake()),
            user_id: generate_snowflake()
          })

        audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

        assert :ok =
                 GuildAuditLogEntry.create(
                   audit_log_entry_event,
                   %Nostrum.Struct.WSState{},
                   context
                 )
      end

      entries = TestApp.Discord.GuildAuditLogEntry.read!()
      assert length(entries) == 3

      action_types = Enum.map(entries, & &1.action_type) |> Enum.sort()
      assert action_types == [10, 11, 12]
    end

    @tag :fixed
    test "handles member action types (20-28)" do
      member_actions = [
        {20, "Member kicked"},
        {21, "Member pruned"},
        {22, "Member banned"}
      ]

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      for {action_type, reason} <- member_actions do
        entry =
          guild_audit_log_entry(%{
            action_type: action_type,
            changes: nil,
            options: nil,
            reason: reason,
            target_id: to_string(generate_snowflake()),
            user_id: generate_snowflake()
          })

        audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

        assert :ok =
                 GuildAuditLogEntry.create(
                   audit_log_entry_event,
                   %Nostrum.Struct.WSState{},
                   context
                 )
      end

      entries = TestApp.Discord.GuildAuditLogEntry.read!()
      assert length(entries) == 3

      action_types = Enum.map(entries, & &1.action_type) |> Enum.sort()
      assert action_types == [20, 21, 22]
    end

    @tag :fixed
    test "handles role action types (30-32)" do
      role_actions = [
        {30, "Role created"},
        {31, "Role updated"},
        {32, "Role deleted"}
      ]

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      for {action_type, reason} <- role_actions do
        entry =
          guild_audit_log_entry(%{
            action_type: action_type,
            changes: nil,
            options: nil,
            reason: reason,
            target_id: to_string(generate_snowflake()),
            user_id: generate_snowflake()
          })

        audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

        assert :ok =
                 GuildAuditLogEntry.create(
                   audit_log_entry_event,
                   %Nostrum.Struct.WSState{},
                   context
                 )
      end

      entries = TestApp.Discord.GuildAuditLogEntry.read!()
      assert length(entries) == 3

      action_types = Enum.map(entries, & &1.action_type) |> Enum.sort()
      assert action_types == [30, 31, 32]
    end

    @tag :fixed
    test "handles message action types (72-73)" do
      entry =
        guild_audit_log_entry(%{
          action_type: 72,
          changes: nil,
          options: %{"count" => "10"},
          reason: "Spam messages deleted",
          target_id: to_string(generate_snowflake()),
          user_id: generate_snowflake()
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildAuditLogEntry,
        guild: nil,
        user: nil,
        context: nil
      }

      audit_log_entry_event = Payloads.GuildAuditLogEntryCreateEvent.new!(entry)

      assert :ok =
               GuildAuditLogEntry.create(
                 audit_log_entry_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      assert [created_entry] = TestApp.Discord.GuildAuditLogEntry.read!()
      assert created_entry.action_type == 72
      assert created_entry.options["count"] == "10"
    end
  end
end
