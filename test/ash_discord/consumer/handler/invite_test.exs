defmodule AshDiscord.Consumer.Handler.InviteTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord
  import Mimic

  alias AshDiscord.Consumer.Handler.Invite
  alias TestApp.TestConsumer

  setup do
    copy(Nostrum.Api.Guild)
    copy(Nostrum.Api.Channel)
    :ok
  end

  describe "create/4" do
    test "creates invite in database" do
      invite_data = invite()

      # Mock guild and channel API calls for relationships
      expect(Nostrum.Api.Guild, :get, fn _guild_id ->
        {:ok, guild()}
      end)

      expect(Nostrum.Api.Channel, :get, fn _channel_id ->
        {:ok, channel()}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Invite.create(TestConsumer, invite_data, %Nostrum.Struct.WSState{}, context)

      # Verify invite was created in database
      invites = TestApp.Discord.Invite.read!()
      assert length(invites) == 1

      created_invite = hd(invites)
      assert created_invite.code == invite_data.code
    end
  end

  describe "delete/4" do
    test "deletes invite from database" do
      invite_data = invite()

      # Mock API calls for creation
      expect(Nostrum.Api.Guild, :get, fn _guild_id ->
        {:ok, guild()}
      end)

      expect(Nostrum.Api.Channel, :get, fn _channel_id ->
        {:ok, channel()}
      end)

      # First create the invite
      {:ok, _created} =
        TestApp.Discord.Invite
        |> Ash.Changeset.for_create(:from_discord, %{
          discord_struct: invite_data
        })
        |> Ash.create()

      # Verify invite exists
      invites_before = TestApp.Discord.Invite.read!()
      assert length(invites_before) == 1

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Invite.delete(TestConsumer, invite_data, %Nostrum.Struct.WSState{}, context)

      # Verify invite was deleted from database
      invites_after = TestApp.Discord.Invite.read!()
      assert length(invites_after) == 0
    end

    test "handles missing invite gracefully" do
      invite_data = invite()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      # Should not crash when invite doesn't exist
      assert :ok =
               Invite.delete(TestConsumer, invite_data, %Nostrum.Struct.WSState{}, context)
    end
  end
end
