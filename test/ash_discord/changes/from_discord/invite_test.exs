defmodule AshDiscord.Changes.FromDiscord.InviteTest do
  @moduledoc """
  Comprehensive tests for Invite entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates invite from discord struct with all attributes" do
      guild_id = 555_666_777
      channel_id = 111_222_333
      inviter_id = 987_654_321

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user"})}
      end)

      invite_struct =
        invite(%{
          code: "abc123def",
          guild: guild(%{id: guild_id}),
          channel: channel(%{id: channel_id}),
          inviter: user(%{id: inviter_id}),
          target_user_type: nil,
          target_user: nil,
          uses: 5,
          max_uses: 10,
          max_age: 3600,
          temporary: false,
          created_at: "2023-01-15T10:30:00Z"
        })

      created_invite =
        TestApp.Discord.invite_from_discord!(%{data: invite_struct},
          load: [:guild, :channel, :inviter, :target_user]
        )

      assert created_invite.code == invite_struct.code
      assert created_invite.guild.discord_id == guild_id
      assert created_invite.channel.discord_id == channel_id
      assert created_invite.target_user_type == nil
      assert created_invite.target_user == nil
      assert created_invite.uses == invite_struct.uses
      assert created_invite.max_uses == invite_struct.max_uses
      assert created_invite.max_age == invite_struct.max_age
      assert created_invite.temporary == false
      assert created_invite.created_at == ~U[2023-01-15 10:30:00Z]
    end

    @tag :fixed
    test "handles permanent invite" do
      guild_id = 777_888_999
      channel_id = 333_444_555
      inviter_id = 111_222_333

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user"})}
      end)

      invite_struct =
        invite(%{
          code: "permanent123",
          guild: guild(%{id: guild_id}),
          channel: channel(%{id: channel_id}),
          inviter: user(%{id: inviter_id}),
          target_user_type: nil,
          target_user: nil,
          uses: 0,
          max_uses: 0,
          max_age: 0,
          temporary: false,
          created_at: "2023-02-01T12:00:00Z"
        })

      created_invite =
        TestApp.Discord.invite_from_discord!(%{data: invite_struct},
          load: [:guild, :channel, :inviter]
        )

      assert created_invite.code == invite_struct.code
      assert created_invite.max_uses == 0
      assert created_invite.max_age == 0
      assert created_invite.temporary == false
    end

    @tag :fixed
    test "handles temporary invite" do
      guild_id = 999_111_222
      channel_id = 444_555_666
      inviter_id = 777_888_999

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user"})}
      end)

      invite_struct =
        invite(%{
          code: "temp456def",
          guild: guild(%{id: guild_id}),
          channel: channel(%{id: channel_id}),
          inviter: user(%{id: inviter_id}),
          target_user_type: nil,
          target_user: nil,
          uses: 1,
          max_uses: 1,
          max_age: 1800,
          temporary: true,
          created_at: "2023-03-10T15:30:00Z"
        })

      created_invite =
        TestApp.Discord.invite_from_discord!(%{data: invite_struct},
          load: [:guild, :channel, :inviter]
        )

      assert created_invite.code == invite_struct.code
      assert created_invite.temporary == true
      assert created_invite.max_uses == 1
      assert created_invite.max_age == 1800
    end

    @tag :fixed
    test "handles stream target invite" do
      guild_id = 333_444_555
      channel_id = 666_777_888
      inviter_id = 999_111_222
      target_user_id = 123_456_789

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user_#{id}"})}
      end)

      invite_struct =
        invite(%{
          code: "stream789ghi",
          guild: guild(%{id: guild_id}),
          channel: channel(%{id: channel_id}),
          inviter: user(%{id: inviter_id}),
          target_user_type: 1,
          target_user: user(%{id: target_user_id}),
          uses: 0,
          max_uses: 5,
          max_age: 3600,
          temporary: false,
          created_at: "2023-04-05T09:00:00Z"
        })

      created_invite =
        TestApp.Discord.invite_from_discord!(%{data: invite_struct},
          load: [:guild, :channel, :inviter, :target_user]
        )

      assert created_invite.code == invite_struct.code
      assert created_invite.target_user_type == 1
    end

    @tag :fixed
    test "handles embedded application target invite" do
      guild_id = 777_888_999
      channel_id = 111_222_333
      inviter_id = 444_555_666

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user"})}
      end)

      invite_struct =
        invite(%{
          code: "app012jkl",
          guild: guild(%{id: guild_id}),
          channel: channel(%{id: channel_id}),
          inviter: user(%{id: inviter_id}),
          target_user_type: 2,
          target_user: nil,
          uses: 3,
          max_uses: 10,
          max_age: 7200,
          temporary: false,
          created_at: "2023-05-12T14:20:00Z"
        })

      created_invite =
        TestApp.Discord.invite_from_discord!(%{data: invite_struct},
          load: [:guild, :channel, :inviter, :target_user]
        )

      assert created_invite.code == invite_struct.code
      assert created_invite.target_user_type == 2
      assert created_invite.target_user == nil
    end

    @tag :fixed
    test "handles invite without inviter" do
      guild_id = 555_666_777
      channel_id = 888_999_111

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      invite_struct =
        invite(%{
          code: "noinviter345",
          guild: guild(%{id: guild_id}),
          channel: channel(%{id: channel_id}),
          inviter: nil,
          target_user_type: nil,
          target_user: nil,
          uses: 50,
          max_uses: 0,
          max_age: 0,
          temporary: false,
          created_at: "2023-06-01T18:45:00Z"
        })

      created_invite =
        TestApp.Discord.invite_from_discord!(%{data: invite_struct},
          load: [:guild, :channel, :inviter]
        )

      assert created_invite.code == invite_struct.code
      assert created_invite.inviter == nil
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches invite from API when data not provided" do
      invite_code = "abc123def"
      guild_id = 555_666_777
      channel_id = 111_222_333
      inviter_id = 987_654_321

      expect(Nostrum.Api.Invite, :get, fn code ->
        {:ok,
         invite(%{
           code: code,
           guild: guild(%{id: guild_id}),
           channel: channel(%{id: channel_id}),
           inviter: user(%{id: inviter_id}),
           uses: 10,
           max_uses: 100,
           max_age: 7200,
           temporary: false,
           created_at: "2023-08-15T14:30:00Z"
         })}
      end)

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user"})}
      end)

      created_invite =
        TestApp.Discord.invite_from_discord!(%{identity: invite_code},
          load: [:guild, :channel, :inviter]
        )

      assert created_invite.code == invite_code
      assert created_invite.guild.discord_id == guild_id
      assert created_invite.channel.discord_id == channel_id
      assert created_invite.uses == 10
      assert created_invite.max_uses == 100
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing invite instead of creating duplicate" do
      code = "upsert123"
      guild_id = 555_666_777
      channel_id = 111_222_333
      inviter_id = 987_654_321

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user"})}
      end)

      initial_struct =
        invite(%{
          code: code,
          guild: guild(%{id: guild_id}),
          channel: channel(%{id: channel_id}),
          inviter: user(%{id: inviter_id}),
          uses: 0,
          max_uses: 5,
          max_age: 3600,
          temporary: false,
          created_at: "2023-01-01T00:00:00Z"
        })

      original_invite = TestApp.Discord.invite_from_discord!(%{data: initial_struct})

      updated_struct =
        invite(%{
          code: code,
          guild: guild(%{id: guild_id}),
          channel: channel(%{id: channel_id}),
          inviter: user(%{id: inviter_id}),
          uses: 3,
          max_uses: 5,
          max_age: 3600,
          temporary: false,
          created_at: "2023-01-01T00:00:00Z"
        })

      updated_invite = TestApp.Discord.invite_from_discord!(%{data: updated_struct})

      assert updated_invite.id == original_invite.id
      assert updated_invite.code == original_invite.code
      assert updated_invite.uses == 3
    end

    @tag :fixed
    test "upsert works with usage limit changes" do
      code = "limit456"
      guild_id = 777_888_999
      channel_id = 333_444_555
      inviter_id = 111_222_333

      stub(Nostrum.Api.Guild, :get, fn id ->
        {:ok, guild(%{id: id, name: "Test Guild"})}
      end)

      stub(Nostrum.Api.Channel, :get, fn id ->
        {:ok, channel(%{id: id, name: "test-channel", type: 0})}
      end)

      stub(Nostrum.Api.User, :get, fn id ->
        {:ok, user(%{id: id, username: "test_user"})}
      end)

      initial_struct =
        invite(%{
          code: code,
          guild: guild(%{id: guild_id}),
          channel: channel(%{id: channel_id}),
          inviter: user(%{id: inviter_id}),
          uses: 0,
          max_uses: 1,
          max_age: 1800,
          temporary: true,
          created_at: "2023-07-01T10:00:00Z"
        })

      original_invite = TestApp.Discord.invite_from_discord!(%{data: initial_struct})

      updated_struct =
        invite(%{
          code: code,
          guild: guild(%{id: guild_id}),
          channel: channel(%{id: channel_id}),
          inviter: user(%{id: inviter_id}),
          uses: 0,
          max_uses: 0,
          max_age: 0,
          temporary: false,
          created_at: "2023-07-01T10:00:00Z"
        })

      updated_invite = TestApp.Discord.invite_from_discord!(%{data: updated_struct})

      assert updated_invite.id == original_invite.id
      assert updated_invite.code == code
      assert updated_invite.max_uses == 0
      assert updated_invite.max_age == 0
      assert updated_invite.temporary == false
    end
  end
end
