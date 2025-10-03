defmodule AshDiscord.Consumer.Handler.Guild.MemberTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord
  import Mimic

  require Ash.Query

  alias AshDiscord.Consumer.Handler.Guild.Member
  alias TestApp.TestConsumer

  setup do
    copy(Nostrum.Api.User)
    :ok
  end

  describe "add/4" do
    test "creates guild member in database" do
      guild_id = generate_snowflake()
      member_data = member()

      # Mock user API call for relationship - return user with matching ID
      expect(Nostrum.Api.User, :get, fn user_id ->
        {:ok, user(%{id: user_id})}
      end)

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

      # Mock user API call for relationship - return user with matching ID
      expect(Nostrum.Api.User, :get, fn user_id ->
        {:ok, user(%{id: user_id})}
      end)

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

      # Mock user API call for relationship - return user with matching ID
      expect(Nostrum.Api.User, :get, fn user_id ->
        {:ok, user(%{id: user_id})}
      end)

      # First create the guild member
      {:ok, _created} =
        TestApp.Discord.GuildMember
        |> Ash.Changeset.for_create(:from_discord, %{
          guild_id: guild_id,
          discord_struct: member_data
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
