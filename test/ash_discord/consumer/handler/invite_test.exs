defmodule AshDiscord.Consumer.Handler.InviteTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Invite
  alias TestApp.TestConsumer

  describe "create/4" do
    @tag :fixed
    test "creates invite in database with all relationships" do
      # Create prerequisite records for all relationships
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      inviter_data = user()
      target_user_data = user()

      invite_data =
        invite(%{
          guild: guild_data,
          channel: channel_data,
          inviter: inviter_data,
          target_user: target_user_data,
          target_user_type: 1
        })

      # Persist all prerequisite records
      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: inviter_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: target_user_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Invite,
        guild: nil,
        user: nil
      }

      assert :ok =
               Invite.create(TestConsumer, invite_data, %Nostrum.Struct.WSState{}, context)

      [created_invite] =
        TestApp.Discord.Invite
        |> Ash.Query.load([:guild, :channel, :inviter, :target_user])
        |> Ash.read!(authorize?: false)

      assert created_invite.code == invite_data.code
      assert created_invite.guild.discord_id == invite_data.guild.id
      assert created_invite.channel.discord_id == invite_data.channel.id
      assert created_invite.inviter.discord_id == invite_data.inviter.id
      assert created_invite.target_user.discord_id == invite_data.target_user.id
    end
  end

  describe "delete/4" do
    @tag :fixed
    test "deletes invite from database" do
      # Create prerequisite records for relationships
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      inviter_data = user()

      invite_data =
        invite(%{
          guild: guild_data,
          channel: channel_data,
          inviter: inviter_data
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: inviter_data}, authorize?: false)
      TestApp.Discord.invite_from_discord!(%{data: invite_data}, authorize?: false)

      assert [_] = TestApp.Discord.Invite.read!(authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Invite,
        guild: nil,
        user: nil
      }

      assert :ok =
               Invite.delete(TestConsumer, invite_data, %Nostrum.Struct.WSState{}, context)

      assert [] = TestApp.Discord.Invite.read!(authorize?: false)
    end

    @tag :fixed
    test "handles missing invite gracefully" do
      invite_data = invite()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Invite,
        guild: nil,
        user: nil
      }

      assert :ok =
               Invite.delete(TestConsumer, invite_data, %Nostrum.Struct.WSState{}, context)
    end
  end
end
