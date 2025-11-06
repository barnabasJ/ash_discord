defmodule AshDiscord.Consumer.Handler.GuildMemberTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  require Ash.Query

  alias AshDiscord.Consumer.Handler.GuildMember
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "add/4" do
    @tag :fixed
    test "creates guild member in database" do
      guild = guild()
      user = user()
      member_data = member(%{user_id: user.id})

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      member_payload = Payloads.Member.new!(member_data)

      guild_member_add = %Payloads.GuildMemberAdd{
        guild_id: guild.id,
        member: member_payload
      }

      assert :ok =
               GuildMember.add(
                 guild_member_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [created_member] =
        TestApp.Discord.GuildMember
        |> Ash.Query.filter(guild_discord_id: guild.id)
        |> Ash.read!(authorize?: false)

      assert created_member.user_discord_id == member_data.user_id
      assert created_member.guild_discord_id == guild.id
    end
  end

  describe "update/4" do
    @tag :fixed
    test "updates existing guild member in database" do
      guild = guild()
      user = user()
      new_member = member(%{user_id: user.id, nick: "New Nick"})

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      new_member_payload = Payloads.Member.new!(new_member)

      guild_member_update = %Payloads.GuildMemberUpdate{
        guild_id: guild.id,
        old_member: nil,
        new_member: new_member_payload
      }

      assert :ok =
               GuildMember.update(
                 guild_member_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [updated_member] =
        TestApp.Discord.GuildMember
        |> Ash.Query.filter(guild_discord_id: guild.id)
        |> Ash.read!(authorize?: false)

      assert updated_member.user_discord_id == new_member.user_id
      assert updated_member.guild_discord_id == guild.id
      assert updated_member.nick == "New Nick"
    end
  end

  describe "remove/4" do
    @tag :fixed
    test "removes guild member from database" do
      guild = guild()
      user = user()
      member_data = member(%{user_id: user.id})

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user}, authorize?: false)

      TestApp.Discord.guild_member_from_discord!(
        %{
          data: member_data,
          identity: %{guild_discord_id: guild.id, user_discord_id: member_data.user_id}
        },
        authorize?: false
      )

      [_member] =
        TestApp.Discord.GuildMember
        |> Ash.Query.filter(guild_discord_id: guild.id)
        |> Ash.read!(authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      member_payload = Payloads.Member.new!(member_data)

      guild_member_remove = %Payloads.GuildMemberRemove{
        guild_id: guild.id,
        member: member_payload
      }

      assert :ok =
               GuildMember.remove(
                 guild_member_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [] =
        TestApp.Discord.GuildMember
        |> Ash.Query.filter(guild_discord_id: guild.id)
        |> Ash.read!(authorize?: false)
    end

    @tag :fixed
    test "handles missing member gracefully" do
      guild = guild()
      user = user()
      member_data = member(%{user_id: user.id})

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      member_payload = Payloads.Member.new!(member_data)

      guild_member_remove = %Payloads.GuildMemberRemove{
        guild_id: guild.id,
        member: member_payload
      }

      assert :ok =
               GuildMember.remove(
                 guild_member_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end

  describe "chunk/4" do
    @tag :fixed
    test "handles GUILD_MEMBERS_CHUNK event and returns :ok" do
      guild = guild()

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      chunk_event = %Payloads.GuildMembersChunkEvent{
        data: %{
          guild_id: guild.id,
          members: [],
          chunk_index: 0,
          chunk_count: 1
        }
      }

      assert :ok =
               GuildMember.chunk(
                 chunk_event,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end

    @tag :fixed
    test "creates guild members from chunk event data" do
      guild = guild()
      user1 = user()
      user2 = user()

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user1}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user2}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      chunk_event = %Payloads.GuildMembersChunkEvent{
        data: %{
          guild_id: guild.id,
          members: [
            %{user_id: user1.id, nick: "TestUser1", roles: []},
            %{user_id: user2.id, nick: "TestUser2", roles: []}
          ],
          chunk_index: 0,
          chunk_count: 1,
          nonce: "test_nonce"
        }
      }

      assert :ok =
               GuildMember.chunk(
                 chunk_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      members = TestApp.Discord.GuildMember.read!(authorize?: false)
      assert length(members) == 2

      member_user_ids = Enum.map(members, & &1.user_discord_id)
      assert user1.id in member_user_ids
      assert user2.id in member_user_ids

      member1 = Enum.find(members, &(&1.user_discord_id == user1.id))
      assert member1.guild_discord_id == guild.id
      assert member1.nick == "TestUser1"

      member2 = Enum.find(members, &(&1.user_discord_id == user2.id))
      assert member2.guild_discord_id == guild.id
      assert member2.nick == "TestUser2"
    end
  end
end
