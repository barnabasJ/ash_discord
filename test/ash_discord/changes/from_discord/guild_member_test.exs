defmodule AshDiscord.Changes.FromDiscord.GuildMemberTest do
  @moduledoc """
  Comprehensive tests for GuildMember entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates guild member from discord struct with all attributes" do
      user_id = 123_456_789
      guild_id = 555_666_777

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      {:ok, datetime, 0} = DateTime.from_iso8601("2023-01-15T10:30:00Z")

      member_struct =
        guild_member(%{
          user_id: user_id,
          nick: "TestNick",
          joined_at: DateTime.to_unix(datetime, :millisecond),
          deaf: false,
          mute: false
        })

      created_member =
        TestApp.Discord.guild_member_from_discord!(
          %{
            data: member_struct,
            identity: %{guild_discord_id: guild_id}
          },
          load: [:user, :guild]
        )

      assert created_member.nick == member_struct.nick
      assert created_member.joined_at == ~U[2023-01-15 10:30:00Z]
      assert created_member.deaf == false
      assert created_member.mute == false
      assert created_member.user.discord_id == user_id
      assert created_member.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles member without nickname" do
      user_id = 987_654_321
      guild_id = 555_666_777

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      {:ok, datetime, 0} = DateTime.from_iso8601("2023-02-20T15:45:00Z")

      member_struct =
        guild_member(%{
          user_id: user_id,
          nick: nil,
          joined_at: DateTime.to_unix(datetime, :millisecond),
          deaf: false,
          mute: false
        })

      created_member =
        TestApp.Discord.guild_member_from_discord!(
          %{
            data: member_struct,
            identity: %{guild_discord_id: guild_id}
          },
          load: [:user, :guild]
        )

      assert created_member.nick == nil
      assert created_member.joined_at == ~U[2023-02-20 15:45:00Z]
      assert created_member.user.discord_id == user_id
      assert created_member.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles deafened member" do
      user_id = 111_222_333
      guild_id = 555_666_777

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      {:ok, datetime, 0} = DateTime.from_iso8601("2023-03-10T08:15:00Z")

      member_struct =
        guild_member(%{
          user_id: user_id,
          nick: "DeafUser",
          joined_at: DateTime.to_unix(datetime, :millisecond),
          deaf: true,
          mute: false
        })

      created_member =
        TestApp.Discord.guild_member_from_discord!(
          %{
            data: member_struct,
            identity: %{guild_discord_id: guild_id}
          },
          load: [:user, :guild]
        )

      assert created_member.deaf == true
      assert created_member.mute == false
      assert created_member.user.discord_id == user_id
      assert created_member.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles muted member" do
      user_id = 777_888_999
      guild_id = 555_666_777

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      {:ok, datetime, 0} = DateTime.from_iso8601("2023-04-05T12:00:00Z")

      member_struct =
        guild_member(%{
          user_id: user_id,
          nick: "MuteUser",
          joined_at: DateTime.to_unix(datetime, :millisecond),
          deaf: false,
          mute: true
        })

      created_member =
        TestApp.Discord.guild_member_from_discord!(
          %{
            data: member_struct,
            identity: %{guild_discord_id: guild_id}
          },
          load: [:user, :guild]
        )

      assert created_member.deaf == false
      assert created_member.mute == true
      assert created_member.user.discord_id == user_id
      assert created_member.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles member with both deaf and mute" do
      user_id = 333_444_555
      guild_id = 555_666_777

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      {:ok, datetime, 0} = DateTime.from_iso8601("2023-05-12T18:30:00Z")

      member_struct =
        guild_member(%{
          user_id: user_id,
          nick: "SilentUser",
          joined_at: DateTime.to_unix(datetime, :millisecond),
          deaf: true,
          mute: true
        })

      created_member =
        TestApp.Discord.guild_member_from_discord!(
          %{
            data: member_struct,
            identity: %{guild_discord_id: guild_id}
          },
          load: [:user, :guild]
        )

      assert created_member.deaf == true
      assert created_member.mute == true
      assert created_member.user.discord_id == user_id
      assert created_member.guild.discord_id == guild_id
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches guild member from API when data not provided" do
      guild_id = 555_666_777
      user_id = 999_888_777

      {:ok, datetime_premium, 0} = DateTime.from_iso8601("2023-07-01T12:00:00Z")
      {:ok, datetime_joined, 0} = DateTime.from_iso8601("2023-06-15T10:00:00Z")

      expect(Nostrum.Api.Guild, :member, fn ^guild_id, ^user_id ->
        {:ok,
         guild_member(%{
           user_id: user_id,
           nick: "API_Fetched_Nick",
           joined_at: DateTime.to_unix(datetime_joined, :millisecond),
           premium_since: datetime_premium,
           deaf: false,
           mute: true,
           roles: [123_456, 789_012]
         })}
      end)

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      created_member =
        TestApp.Discord.guild_member_from_discord!(
          %{
            identity: %{guild_discord_id: guild_id, user_discord_id: user_id}
          },
          load: [:user, :guild]
        )

      assert created_member.nick == "API_Fetched_Nick"
      assert created_member.mute == true
      assert created_member.deaf == false
      assert created_member.roles == [123_456, 789_012]
      assert created_member.user.discord_id == user_id
      assert created_member.guild.discord_id == guild_id
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing guild member instead of creating duplicate" do
      user_id = 555_666_777
      guild_id = 111_222_333

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      {:ok, datetime, 0} = DateTime.from_iso8601("2023-01-01T00:00:00Z")

      initial_struct =
        guild_member(%{
          user_id: user_id,
          nick: "OriginalNick",
          joined_at: DateTime.to_unix(datetime, :millisecond),
          deaf: false,
          mute: false
        })

      original_member =
        TestApp.Discord.guild_member_from_discord!(%{
          data: initial_struct,
          identity: %{guild_discord_id: guild_id}
        })

      updated_struct =
        guild_member(%{
          user_id: user_id,
          nick: "UpdatedNick",
          joined_at: DateTime.to_unix(datetime, :millisecond),
          deaf: true,
          mute: true
        })

      updated_member =
        TestApp.Discord.guild_member_from_discord!(%{
          data: updated_struct,
          identity: %{guild_discord_id: guild_id}
        })

      assert updated_member.id == original_member.id

      assert updated_member.nick == "UpdatedNick"
      assert updated_member.deaf == true
      assert updated_member.mute == true
    end

    @tag :fixed
    test "upsert works with nickname changes" do
      user_id = 333_444_555
      guild_id = 777_888_999

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      {:ok, datetime, 0} = DateTime.from_iso8601("2023-06-01T12:00:00Z")

      initial_struct =
        guild_member(%{
          user_id: user_id,
          nick: "OldNick",
          joined_at: DateTime.to_unix(datetime, :millisecond),
          deaf: false,
          mute: false
        })

      original_member =
        TestApp.Discord.guild_member_from_discord!(%{
          data: initial_struct,
          identity: %{guild_discord_id: guild_id}
        })

      updated_struct =
        guild_member(%{
          user_id: user_id,
          nick: nil,
          joined_at: DateTime.to_unix(datetime, :millisecond),
          deaf: false,
          mute: false
        })

      updated_member =
        TestApp.Discord.guild_member_from_discord!(%{
          data: updated_struct,
          identity: %{guild_discord_id: guild_id}
        })

      assert updated_member.id == original_member.id

      assert updated_member.nick == nil
    end
  end
end
