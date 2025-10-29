defmodule AshDiscord.Consumer.Handler.ThreadTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Thread
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    @tag :fixed
    test "creates thread from Discord event" do
      thread_data = thread()
      typed_thread = Payloads.Thread.new!(thread_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Thread,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.create(typed_thread, %Nostrum.Struct.WSState{}, context)

      assert [created_thread] = TestApp.Discord.Thread.read!(authorize?: false)
      assert created_thread.discord_id == thread_data.id
      assert created_thread.name == thread_data.name
      assert created_thread.type == thread_data.type
    end

    @tag :fixed
    test "handles threads with metadata" do
      thread_data =
        thread(%{
          thread_metadata: %{
            archived: true,
            auto_archive_duration: 4320,
            locked: false
          }
        })

      typed_thread = Payloads.Thread.new!(thread_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Thread,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.create(typed_thread, %Nostrum.Struct.WSState{}, context)

      assert [created] = TestApp.Discord.Thread.read!(authorize?: false)
      assert created.thread_metadata.archived == true
      assert created.thread_metadata.auto_archive_duration == 4320
    end
  end

  describe "delete/3" do
    @tag :fixed
    test "deletes thread when it exists" do
      thread_data = thread()

      TestApp.Discord.thread_from_discord!(%{data: Payloads.Thread.new!(thread_data)},
        authorize?: false
      )

      typed_delete = Payloads.ThreadDelete.new!(thread_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Thread,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.delete(typed_delete, %Nostrum.Struct.WSState{}, context)

      assert [] = TestApp.Discord.Thread.read!(authorize?: false)
    end

    @tag :fixed
    test "handles deletion of non-existent thread gracefully" do
      thread_data = thread()
      typed_delete = Payloads.ThreadDelete.new!(thread_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Thread,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.delete(typed_delete, %Nostrum.Struct.WSState{}, context)
    end
  end

  describe "update/3" do
    @tag :fixed
    test "updates existing thread" do
      old_thread = thread(%{name: "Old Thread Name"})
      new_thread = thread(%{id: old_thread.id, name: "New Thread Name"})

      thread_update = Payloads.ThreadUpdate.new!({old_thread, new_thread})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Thread,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.update(thread_update, %Nostrum.Struct.WSState{}, context)

      assert [updated] = TestApp.Discord.Thread.read!(authorize?: false)
      assert updated.discord_id == new_thread.id
      assert updated.name == "New Thread Name"
    end

    @tag :fixed
    test "creates thread if it doesn't exist (upsert)" do
      thread_data = thread()
      thread_update = Payloads.ThreadUpdate.new!({thread_data, thread_data})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Thread,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.update(thread_update, %Nostrum.Struct.WSState{}, context)

      assert [_thread] = TestApp.Discord.Thread.read!(authorize?: false)
    end
  end

  describe "list_sync/3" do
    @tag :fixed
    test "processes thread list sync event" do
      thread1 = thread()
      thread2 = thread()
      guild_id = generate_snowflake()

      sync_event = %Nostrum.Struct.Event.ThreadListSync{
        guild_id: guild_id,
        channel_ids: [thread1.parent_id, thread2.parent_id],
        threads: [thread1, thread2],
        members: []
      }

      typed_sync = Payloads.ThreadListSyncEvent.new!(sync_event)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ThreadListSync,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.list_sync(typed_sync, %Nostrum.Struct.WSState{}, context)

      assert [sync] = TestApp.Discord.ThreadListSync.read!(authorize?: false)
      assert sync.guild_discord_id == guild_id
      assert length(sync.channel_ids) == 2
    end
  end

  describe "member_update/3" do
    @tag :fixed
    test "creates or updates thread member" do
      member_data =
        thread_member(%{
          id: generate_snowflake(),
          user_id: generate_snowflake(),
          flags: 1
        })

      typed_member = Payloads.ThreadMember.new!(member_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ThreadMember,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.member_update(typed_member, %Nostrum.Struct.WSState{}, context)

      assert [created_member] = TestApp.Discord.ThreadMember.read!(authorize?: false)
      assert created_member.thread_discord_id == member_data.id
      assert created_member.user_discord_id == member_data.user_id
      assert created_member.flags == member_data.flags
    end

    @tag :fixed
    test "upserts thread member on duplicate" do
      member_data =
        thread_member(%{
          id: generate_snowflake(),
          user_id: generate_snowflake(),
          flags: 0
        })

      typed_member = Payloads.ThreadMember.new!(member_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ThreadMember,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.member_update(typed_member, %Nostrum.Struct.WSState{}, context)

      updated_member =
        thread_member(%{
          id: member_data.id,
          user_id: member_data.user_id,
          flags: 3
        })

      typed_updated = Payloads.ThreadMember.new!(updated_member)

      assert :ok = Thread.member_update(typed_updated, %Nostrum.Struct.WSState{}, context)

      assert [updated] = TestApp.Discord.ThreadMember.read!(authorize?: false)
      assert updated.flags == 3
    end
  end

  describe "members_update/3" do
    @tag :fixed
    test "processes thread members update event" do
      thread_id = generate_snowflake()
      guild_id = generate_snowflake()
      added_member = thread_member(%{id: thread_id, user_id: generate_snowflake()})

      members_update_event = %Nostrum.Struct.Event.ThreadMembersUpdate{
        id: thread_id,
        guild_id: guild_id,
        member_count: 5,
        added_members: [added_member],
        removed_member_ids: [generate_snowflake()]
      }

      typed_update = Payloads.ThreadMembersUpdateEvent.new!(members_update_event)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ThreadMembersUpdate,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.members_update(typed_update, %Nostrum.Struct.WSState{}, context)

      assert [update] = TestApp.Discord.ThreadMembersUpdate.read!(authorize?: false)
      assert update.thread_discord_id == thread_id
      assert update.guild_discord_id == guild_id
      assert update.member_count == 5
      assert length(update.added_members) == 1
      assert length(update.removed_member_ids) == 1
    end

    @tag :fixed
    test "handles members update with no changes" do
      thread_id = generate_snowflake()
      guild_id = generate_snowflake()

      members_update_event = %Nostrum.Struct.Event.ThreadMembersUpdate{
        id: thread_id,
        guild_id: guild_id,
        member_count: 10,
        added_members: [],
        removed_member_ids: []
      }

      typed_update = Payloads.ThreadMembersUpdateEvent.new!(members_update_event)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ThreadMembersUpdate,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.members_update(typed_update, %Nostrum.Struct.WSState{}, context)

      assert [update] = TestApp.Discord.ThreadMembersUpdate.read!(authorize?: false)
      assert update.member_count == 10
      assert Enum.empty?(update.added_members)
      assert Enum.empty?(update.removed_member_ids)
    end
  end
end
