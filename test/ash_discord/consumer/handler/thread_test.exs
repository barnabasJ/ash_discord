defmodule AshDiscord.Consumer.Handler.ThreadTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Thread
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    @tag :fixed
    test "creates thread from Discord event with relationships" do
      guild_data = guild()
      parent_channel_data = channel(%{guild_id: guild_data.id})
      owner_data = user()

      thread_data =
        thread(%{
          guild_id: guild_data.id,
          parent_id: parent_channel_data.id,
          owner_id: owner_data.id
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: parent_channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: owner_data}, authorize?: false)

      typed_thread = Payloads.Thread.new!(thread_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Thread,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.create(typed_thread, %Nostrum.Struct.WSState{}, context)

      [created_thread] =
        TestApp.Discord.Thread
        |> Ash.Query.load([:guild, :parent_channel, :owner])
        |> Ash.read!(authorize?: false)

      assert created_thread.discord_id == thread_data.id
      assert created_thread.name == thread_data.name
      assert created_thread.type == thread_data.type
      assert created_thread.guild.discord_id == guild_data.id
      assert created_thread.parent_channel.discord_id == parent_channel_data.id
      assert created_thread.owner.discord_id == owner_data.id
    end

    @tag :fixed
    test "handles threads with metadata and relationships" do
      guild_data = guild()
      parent_channel_data = channel(%{guild_id: guild_data.id})

      thread_data =
        thread(%{
          guild_id: guild_data.id,
          parent_id: parent_channel_data.id,
          thread_metadata: %{
            archived: true,
            auto_archive_duration: 4320,
            locked: false
          }
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: parent_channel_data}, authorize?: false)

      typed_thread = Payloads.Thread.new!(thread_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Thread,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.create(typed_thread, %Nostrum.Struct.WSState{}, context)

      [created] =
        TestApp.Discord.Thread
        |> Ash.Query.load([:guild, :parent_channel])
        |> Ash.read!(authorize?: false)

      assert created.thread_metadata.archived == true
      assert created.thread_metadata.auto_archive_duration == 4320
      assert created.guild.discord_id == guild_data.id
      assert created.parent_channel.discord_id == parent_channel_data.id
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
    test "processes thread list sync event with guild relationship" do
      guild_data = guild()
      thread1 = thread(%{guild_id: guild_data.id})
      thread2 = thread(%{guild_id: guild_data.id})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)

      sync_event = %Nostrum.Struct.Event.ThreadListSync{
        guild_id: guild_data.id,
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

      [sync] =
        TestApp.Discord.ThreadListSync
        |> Ash.Query.load([:guild])
        |> Ash.read!(authorize?: false)

      assert sync.guild.discord_id == guild_data.id
      assert length(sync.channel_ids) == 2
    end
  end

  describe "member_update/3" do
    @tag :fixed
    test "creates or updates thread member with relationships" do
      guild_data = guild()
      parent_channel_data = channel(%{guild_id: guild_data.id})
      thread_data = thread(%{guild_id: guild_data.id, parent_id: parent_channel_data.id})
      user_data = user()

      member_data =
        thread_member(%{
          id: thread_data.id,
          user_id: user_data.id,
          guild_id: guild_data.id,
          flags: 1
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: parent_channel_data}, authorize?: false)
      TestApp.Discord.thread_from_discord!(%{data: thread_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      typed_member = Payloads.ThreadMember.new!(member_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ThreadMember,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok = Thread.member_update(typed_member, %Nostrum.Struct.WSState{}, context)

      [created_member] =
        TestApp.Discord.ThreadMember
        |> Ash.Query.load([:thread, :user, :guild])
        |> Ash.read!(authorize?: false)

      assert created_member.thread.discord_id == member_data.id
      assert created_member.user.discord_id == member_data.user_id
      assert created_member.guild.discord_id == member_data.guild_id
      assert created_member.flags == member_data.flags
    end

    @tag :fixed
    test "upserts thread member on duplicate with relationships" do
      guild_data = guild()
      parent_channel_data = channel(%{guild_id: guild_data.id})
      thread_data = thread(%{guild_id: guild_data.id, parent_id: parent_channel_data.id})
      user_data = user()

      member_data =
        thread_member(%{
          id: thread_data.id,
          user_id: user_data.id,
          guild_id: guild_data.id,
          flags: 0
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: parent_channel_data}, authorize?: false)
      TestApp.Discord.thread_from_discord!(%{data: thread_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

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
          guild_id: guild_data.id,
          flags: 3
        })

      typed_updated = Payloads.ThreadMember.new!(updated_member)

      assert :ok = Thread.member_update(typed_updated, %Nostrum.Struct.WSState{}, context)

      [updated] =
        TestApp.Discord.ThreadMember
        |> Ash.Query.load([:thread, :user, :guild])
        |> Ash.read!(authorize?: false)

      assert updated.thread.discord_id == thread_data.id
      assert updated.user.discord_id == user_data.id
      assert updated.guild.discord_id == guild_data.id
      assert updated.flags == 3
    end
  end

  describe "members_update/3" do
    @tag :fixed
    test "processes thread members update event with relationships" do
      guild_data = guild()
      parent_channel_data = channel(%{guild_id: guild_data.id})
      thread_data = thread(%{guild_id: guild_data.id, parent_id: parent_channel_data.id})
      added_member = thread_member(%{id: thread_data.id, user_id: generate_snowflake()})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: parent_channel_data}, authorize?: false)
      TestApp.Discord.thread_from_discord!(%{data: thread_data}, authorize?: false)

      members_update_event = %Nostrum.Struct.Event.ThreadMembersUpdate{
        id: thread_data.id,
        guild_id: guild_data.id,
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

      [update] =
        TestApp.Discord.ThreadMembersUpdate
        |> Ash.Query.load([:thread, :guild])
        |> Ash.read!(authorize?: false)

      assert update.thread.discord_id == thread_data.id
      assert update.guild.discord_id == guild_data.id
      assert update.member_count == 5
      assert length(update.added_members) == 1
      assert length(update.removed_member_ids) == 1
    end

    @tag :fixed
    test "handles members update with no changes and relationships" do
      guild_data = guild()
      parent_channel_data = channel(%{guild_id: guild_data.id})
      thread_data = thread(%{guild_id: guild_data.id, parent_id: parent_channel_data.id})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: parent_channel_data}, authorize?: false)
      TestApp.Discord.thread_from_discord!(%{data: thread_data}, authorize?: false)

      members_update_event = %Nostrum.Struct.Event.ThreadMembersUpdate{
        id: thread_data.id,
        guild_id: guild_data.id,
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

      [update] =
        TestApp.Discord.ThreadMembersUpdate
        |> Ash.Query.load([:thread, :guild])
        |> Ash.read!(authorize?: false)

      assert update.thread.discord_id == thread_data.id
      assert update.guild.discord_id == guild_data.id
      assert update.member_count == 10
      assert Enum.empty?(update.added_members)
      assert Enum.empty?(update.removed_member_ids)
    end
  end
end
