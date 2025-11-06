defmodule AshDiscord.Consumer.Handler.ChannelTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Channel
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    @tag :fixed
    test "creates channel in database" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      channel_data =
        channel(%{
          guild_id: guild.id,
          parent_id: nil,
          last_message_id: nil,
          owner_id: nil
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Channel,
        guild: nil,
        user: nil,
        context: nil
      }

      channel_payload = Payloads.Channel.new!(channel_data)

      assert :ok = Channel.create(channel_payload, %Nostrum.Struct.WSState{}, context)

      assert [created_channel] = TestApp.Discord.Channel.read!(authorize?: false)

      assert created_channel.discord_id == channel_data.id
      assert created_channel.name == channel_data.name
    end
  end

  describe "update/3" do
    @tag :fixed
    test "updates existing channel in database" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      old_channel =
        channel(%{
          guild_id: guild.id,
          name: "old-name",
          parent_id: nil,
          last_message_id: nil,
          owner_id: nil
        })

      new_channel =
        channel(%{
          id: old_channel.id,
          guild_id: guild.id,
          name: "new-name",
          parent_id: nil,
          last_message_id: nil,
          owner_id: nil
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Channel,
        guild: nil,
        user: nil,
        context: nil
      }

      old_channel_payload = Payloads.Channel.new!(old_channel)
      new_channel_payload = Payloads.Channel.new!(new_channel)

      channel_update = %Payloads.ChannelUpdate{
        old_channel: old_channel_payload,
        new_channel: new_channel_payload
      }

      assert :ok =
               Channel.update(
                 channel_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [updated_channel] = TestApp.Discord.Channel.read!(authorize?: false)

      assert updated_channel.discord_id == new_channel.id
      assert updated_channel.name == "new-name"
    end
  end

  describe "delete/3" do
    @tag :fixed
    test "deletes channel from database" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      channel_data =
        channel(%{
          guild_id: guild.id,
          parent_id: nil,
          last_message_id: nil,
          owner_id: nil
        })

      channel_payload = Payloads.Channel.new!(channel_data)

      TestApp.Discord.channel_from_discord!(%{data: channel_payload}, authorize?: false)

      [_channel] = TestApp.Discord.Channel.read!(authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Channel,
        guild: nil,
        user: nil,
        context: nil
      }

      assert :ok =
               Channel.delete(channel_payload, %Nostrum.Struct.WSState{}, context)

      [] = TestApp.Discord.Channel.read!(authorize?: false)
    end

    @tag :fixed
    test "handles missing channel gracefully" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      channel_data =
        channel(%{
          guild_id: guild.id,
          parent_id: nil,
          last_message_id: nil,
          owner_id: nil
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Channel,
        guild: nil,
        user: nil,
        context: nil
      }

      channel_payload = Payloads.Channel.new!(channel_data)

      assert :ok =
               Channel.delete(channel_payload, %Nostrum.Struct.WSState{}, context)
    end
  end

  describe "relationship attributes" do
    @tag :fixed
    test "creates channel with parent_discord_id when parent exists" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      parent_channel_data =
        channel(%{
          guild_id: guild.id,
          type: 0,
          parent_id: nil,
          last_message_id: nil,
          owner_id: nil
        })

      parent_payload = Payloads.Channel.new!(parent_channel_data)
      TestApp.Discord.channel_from_discord!(%{data: parent_payload}, authorize?: false)

      child_channel_data =
        channel(%{
          guild_id: guild.id,
          type: 0,
          parent_id: parent_channel_data.id,
          last_message_id: nil,
          owner_id: nil
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Channel,
        guild: nil,
        user: nil,
        context: nil
      }

      child_payload = Payloads.Channel.new!(child_channel_data)

      assert :ok = Channel.create(child_payload, %Nostrum.Struct.WSState{}, context)

      [child] =
        TestApp.Discord.Channel.read!(authorize?: false)
        |> Enum.filter(&(&1.discord_id == child_channel_data.id))

      assert child.parent_discord_id == parent_channel_data.id
    end

    @tag :fixed
    test "creates channel with last_message_discord_id when message exists" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      channel_data =
        channel(%{
          guild_id: guild.id,
          parent_id: nil,
          last_message_id: nil,
          owner_id: nil
        })

      channel_payload = Payloads.Channel.new!(channel_data)
      TestApp.Discord.channel_from_discord!(%{data: channel_payload}, authorize?: false)

      message_data =
        message(%{
          channel_id: channel_data.id,
          guild_id: guild.id
        })

      TestApp.Discord.user_from_discord!(%{data: message_data.author}, authorize?: false)

      message_payload = Payloads.Message.new!(message_data)
      TestApp.Discord.message_from_discord!(%{data: message_payload}, authorize?: false)

      updated_channel_data =
        channel(%{
          id: channel_data.id,
          guild_id: guild.id,
          last_message_id: message_data.id,
          parent_id: nil,
          owner_id: nil
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Channel,
        guild: nil,
        user: nil,
        context: nil
      }

      updated_payload = Payloads.Channel.new!(updated_channel_data)

      assert :ok =
               Channel.update(
                 %Payloads.ChannelUpdate{
                   old_channel: channel_payload,
                   new_channel: updated_payload
                 },
                 %Nostrum.Struct.WSState{},
                 context
               )

      [updated] = TestApp.Discord.Channel.read!(authorize?: false)

      assert updated.last_message_discord_id == message_data.id
    end

    @tag :fixed
    test "creates DM channel with owner_discord_id when owner exists" do
      owner_user = user()
      TestApp.Discord.user_from_discord!(%{data: owner_user}, authorize?: false)

      dm_channel =
        channel(%{
          type: 1,
          guild_id: nil,
          owner_id: owner_user.id,
          parent_id: nil,
          last_message_id: nil
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Channel,
        guild: nil,
        user: nil,
        context: nil
      }

      channel_payload = Payloads.Channel.new!(dm_channel)

      assert :ok = Channel.create(channel_payload, %Nostrum.Struct.WSState{}, context)

      [created_channel] = TestApp.Discord.Channel.read!(authorize?: false)

      assert created_channel.owner_discord_id == owner_user.id
    end
  end

  describe "new fields" do
    @tag :fixed
    test "creates voice channel with voice-specific attributes" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      voice_channel =
        channel(%{
          guild_id: guild.id,
          type: 2,
          bitrate: 128_000,
          user_limit: 10,
          rtc_region: "us-west",
          video_quality_mode: 1,
          parent_id: nil,
          last_message_id: nil,
          owner_id: nil
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Channel,
        guild: nil,
        user: nil,
        context: nil
      }

      channel_payload = Payloads.Channel.new!(voice_channel)

      assert :ok = Channel.create(channel_payload, %Nostrum.Struct.WSState{}, context)

      [created_channel] = TestApp.Discord.Channel.read!(authorize?: false)

      assert created_channel.bitrate == 128_000
      assert created_channel.user_limit == 10
      assert created_channel.rtc_region == "us-west"
      assert created_channel.video_quality_mode == 1
    end

    @tag :fixed
    test "creates thread channel with thread-specific attributes" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      parent_channel = channel(%{guild_id: guild.id, type: 0})
      parent_payload = Payloads.Channel.new!(parent_channel)

      TestApp.Discord.channel_from_discord!(%{data: parent_payload}, authorize?: false)

      thread_channel =
        channel(%{
          guild_id: guild.id,
          parent_id: parent_channel.id,
          type: 11,
          message_count: 42,
          member_count: 5,
          thread_metadata: %{
            archived: false,
            auto_archive_duration: 1440,
            archive_timestamp: DateTime.utc_now(),
            locked: false
          }
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Channel,
        guild: nil,
        user: nil,
        context: nil
      }

      channel_payload = Payloads.Channel.new!(thread_channel)

      assert :ok = Channel.create(channel_payload, %Nostrum.Struct.WSState{}, context)

      [created_channel] =
        TestApp.Discord.Channel.read!(authorize?: false)
        |> Enum.filter(&(&1.discord_id == thread_channel.id))

      assert created_channel.message_count == 42
      assert created_channel.member_count == 5
      assert created_channel.thread_metadata != nil
    end

    @tag :fixed
    test "creates forum channel with forum-specific attributes" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      forum_channel =
        channel(%{
          guild_id: guild.id,
          type: 15,
          available_tags: [
            %{id: 1, name: "Help", moderated: false, emoji_name: "❓"},
            %{id: 2, name: "Bug", moderated: false, emoji_name: "🐛"}
          ],
          default_reaction_emoji: %{emoji_name: "👍"},
          default_sort_order: 0,
          default_forum_layout: 1,
          parent_id: nil,
          last_message_id: nil,
          owner_id: nil
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Channel,
        guild: nil,
        user: nil,
        context: nil
      }

      channel_payload = Payloads.Channel.new!(forum_channel)

      assert :ok = Channel.create(channel_payload, %Nostrum.Struct.WSState{}, context)

      [created_channel] = TestApp.Discord.Channel.read!(authorize?: false)

      assert length(created_channel.available_tags) == 2
      assert created_channel.default_reaction_emoji != nil
      assert created_channel.default_sort_order == 0
      assert created_channel.default_forum_layout == 1
    end
  end
end
