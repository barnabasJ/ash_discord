defmodule AshDiscord.Consumer.Handler.GuildMemberTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators
  use Mimic

  require Ash.Query

  alias AshDiscord.Consumer.Handler.GuildMember
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  setup do
    copy(Nostrum.Api.User)
    copy(Nostrum.Api.Guild)
    :ok
  end

  describe "add/4" do
    test "creates guild member in database" do
      guild_id = generate_snowflake()
      member_data = member()

      # Mock API calls for relationships
      expect(Nostrum.Api.User, :get, fn user_id ->
        {:ok, user(%{id: user_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id})}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      # Create GuildMemberAdd payload
      {:ok, member_payload} = Payloads.Member.new(member_data)

      guild_member_add = %Payloads.GuildMemberAdd{
        guild_id: guild_id,
        member: member_payload
      }

      assert :ok =
               GuildMember.add(
                 guild_member_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify guild member was created in database for this specific guild
      members =
        TestApp.Discord.GuildMember
        |> Ash.Query.filter(guild_id: guild_id)
        |> Ash.read!()

      assert length(members) == 1

      created_member = hd(members)
      assert created_member.user_id == member_data.user_id
      assert created_member.guild_id == guild_id
    end
  end

  describe "update/4" do
    test "updates existing guild member in database" do
      guild_id = generate_snowflake()
      old_member = member(%{nick: "Old Nick"})
      new_member = member(%{user_id: old_member.user_id, nick: "New Nick"})

      # Mock API calls for relationships
      expect(Nostrum.Api.User, :get, fn user_id ->
        {:ok, user(%{id: user_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id})}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      # Create GuildMemberUpdate payload
      {:ok, new_member_payload} = Payloads.Member.new(new_member)

      guild_member_update = %Payloads.GuildMemberUpdate{
        guild_id: guild_id,
        old_member: nil,
        new_member: new_member_payload
      }

      assert :ok =
               GuildMember.update(
                 guild_member_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify guild member was updated (upserted) in database for this specific guild
      members =
        TestApp.Discord.GuildMember
        |> Ash.Query.filter(guild_id: guild_id)
        |> Ash.read!()

      assert length(members) == 1

      updated_member = hd(members)
      assert updated_member.user_id == new_member.user_id
      assert updated_member.guild_id == guild_id
      assert updated_member.nick == "New Nick"
    end
  end

  describe "remove/4" do
    test "removes guild member from database" do
      guild_id = generate_snowflake()
      member_data = member()

      # Mock API calls for relationships
      expect(Nostrum.Api.User, :get, fn user_id ->
        {:ok, user(%{id: user_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id})}
      end)

      # First create the guild member
      {:ok, _created} =
        TestApp.Discord.GuildMember
        |> Ash.Changeset.for_create(:from_discord, %{
          data: member_data,
          identity: %{guild_id: guild_id}
        })
        |> Ash.create()

      # Verify member exists for this specific guild
      members_before =
        TestApp.Discord.GuildMember
        |> Ash.Query.filter(guild_id: guild_id)
        |> Ash.read!()

      assert length(members_before) == 1

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      # Create GuildMemberRemove payload
      {:ok, member_payload} = Payloads.Member.new(member_data)

      guild_member_remove = %Payloads.GuildMemberRemove{
        guild_id: guild_id,
        member: member_payload
      }

      assert :ok =
               GuildMember.remove(
                 guild_member_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify guild member was deleted from database for this specific guild
      members_after =
        TestApp.Discord.GuildMember
        |> Ash.Query.filter(guild_id: guild_id)
        |> Ash.read!()

      assert length(members_after) == 0
    end

    test "handles missing member gracefully" do
      guild_id = generate_snowflake()
      member_data = member()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      # Create GuildMemberRemove payload
      {:ok, member_payload} = Payloads.Member.new(member_data)

      guild_member_remove = %Payloads.GuildMemberRemove{
        guild_id: guild_id,
        member: member_payload
      }

      # Should not crash when member doesn't exist
      assert :ok =
               GuildMember.remove(
                 guild_member_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end

  describe "chunk/4" do
    test "handles GUILD_MEMBERS_CHUNK event and returns :ok" do
      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      chunk_event = %Payloads.GuildMembersChunkEvent{
        data: %{
          guild_id: generate_snowflake(),
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

    test "creates guild members from chunk event data" do
      guild_id = generate_snowflake()
      user_id_1 = generate_snowflake()
      user_id_2 = generate_snowflake()

      # Mock API calls for relationships
      # Each member requires user lookup
      expect(Nostrum.Api.User, :get, 2, fn user_id ->
        {:ok, user(%{id: user_id})}
      end)

      # Guild is fetched once and cached for all members
      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id})}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildMember,
        guild: nil,
        user: nil,
        context: nil
      }

      chunk_event = %Payloads.GuildMembersChunkEvent{
        data: %{
          guild_id: guild_id,
          members: [
            %{user_id: user_id_1, nick: "TestUser1", roles: []},
            %{user_id: user_id_2, nick: "TestUser2", roles: []}
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

      # Verify members were created
      members = TestApp.Discord.GuildMember.read!()
      assert length(members) == 2

      member_user_ids = Enum.map(members, & &1.user_id)
      assert user_id_1 in member_user_ids
      assert user_id_2 in member_user_ids

      member1 = Enum.find(members, &(&1.user_id == user_id_1))
      assert member1.guild_id == guild_id
      assert member1.nick == "TestUser1"

      member2 = Enum.find(members, &(&1.user_id == user_id_2))
      assert member2.guild_id == guild_id
      assert member2.nick == "TestUser2"
    end
  end
end
