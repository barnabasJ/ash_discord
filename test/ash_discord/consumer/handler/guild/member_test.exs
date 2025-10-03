defmodule AshDiscord.Consumer.Handler.Guild.MemberTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Consumer.Handler.Guild.Member
  alias TestApp.TestConsumer

  describe "add/4" do
    test "creates guild member in database" do
      guild_id = generate_snowflake()
      member_data = member()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Member.add(
                 TestConsumer,
                 {guild_id, member_data},
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify guild member was created in database
      members = TestApp.Discord.GuildMember.read!()
      assert length(members) == 1

      created_member = hd(members)
      assert created_member.user_discord_id == member_data.user_id
      assert created_member.guild_discord_id == guild_id
    end
  end

  describe "update/4" do
    test "updates existing guild member in database" do
      guild_id = generate_snowflake()
      old_member = member(%{nick: "Old Nick"})
      new_member = member(%{user_id: old_member.user_id, nick: "New Nick"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Member.update(
                 TestConsumer,
                 {guild_id, old_member, new_member},
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify guild member was updated (upserted) in database
      members = TestApp.Discord.GuildMember.read!()
      assert length(members) == 1

      updated_member = hd(members)
      assert updated_member.user_discord_id == new_member.user_id
      assert updated_member.guild_discord_id == guild_id
      assert updated_member.nick == "New Nick"
    end
  end

  describe "remove/4" do
    test "removes guild member from database" do
      guild_id = generate_snowflake()
      member_data = member()

      # First create the guild member
      {:ok, _created} =
        TestApp.Discord.GuildMember
        |> Ash.Changeset.for_create(:from_discord, %{
          user_discord_id: member_data.user_id,
          guild_discord_id: guild_id,
          discord_struct: member_data
        })
        |> Ash.create()

      # Verify member exists
      members_before = TestApp.Discord.GuildMember.read!()
      assert length(members_before) == 1

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Member.remove(
                 TestConsumer,
                 {guild_id, member_data},
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify guild member was deleted from database
      members_after = TestApp.Discord.GuildMember.read!()
      assert length(members_after) == 0
    end

    test "handles missing member gracefully" do
      guild_id = generate_snowflake()
      member_data = member()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      # Should not crash when member doesn't exist
      assert :ok =
               Member.remove(
                 TestConsumer,
                 {guild_id, member_data},
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end
end
