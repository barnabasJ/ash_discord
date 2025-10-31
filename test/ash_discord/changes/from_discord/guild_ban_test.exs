defmodule AshDiscord.Changes.FromDiscord.GuildBanTest do
  @moduledoc """
  Comprehensive tests for GuildBan entity from_discord transformation.

  Tests struct-first pattern and upsert behavior.
  Note: API fallback pattern not implemented for GuildBan.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  alias AshDiscord.Consumer.Payloads

  describe "struct-first pattern" do
    @tag :fixed
    test "creates guild ban from ban event data with user" do
      guild_id = 555_666_777
      user_id = 999_888_777

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "banned_user"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      user_data = user(%{id: user_id, username: "banned_user"})
      {:ok, user_payload} = Payloads.User.new(user_data)

      created =
        TestApp.Discord.guild_ban_from_discord!(
          %{
            data: %{guild_id: guild_id, user: user_payload}
          },
          load: [:user, :guild]
        )

      assert created.user_discord_id == user_id
      assert created.guild_discord_id == guild_id
      assert created.user.discord_id == user_id
      assert created.guild.discord_id == guild_id
    end

    @tag :fixed
    test "creates guild ban with different user" do
      guild_id = 111_222_333
      user_id = 444_555_666

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "another_banned_user"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Another Guild"})}
      end)

      user_data = user(%{id: user_id, username: "another_banned_user"})
      {:ok, user_payload} = Payloads.User.new(user_data)

      created =
        TestApp.Discord.guild_ban_from_discord!(
          %{
            data: %{guild_id: guild_id, user: user_payload}
          },
          load: [:user, :guild]
        )

      assert created.user_discord_id == user_id
      assert created.guild_discord_id == guild_id
      assert created.user.discord_id == user_id
      assert created.guild.discord_id == guild_id
    end

    @tag :fixed
    test "allows same user banned in different guilds" do
      guild_id_1 = 111_222_333
      guild_id_2 = 444_555_666
      user_id = 777_888_999

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "multi_banned_user"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, 2, fn guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild #{guild_id}"})}
      end)

      user_data = user(%{id: user_id, username: "multi_banned_user"})
      {:ok, user_payload} = Payloads.User.new(user_data)

      ban1 =
        TestApp.Discord.guild_ban_from_discord!(%{
          data: %{guild_id: guild_id_1, user: user_payload}
        })

      ban2 =
        TestApp.Discord.guild_ban_from_discord!(%{
          data: %{guild_id: guild_id_2, user: user_payload}
        })

      assert ban1.id != ban2.id
      assert ban1.user_discord_id == user_id
      assert ban2.user_discord_id == user_id
      assert ban1.guild_discord_id == guild_id_1
      assert ban2.guild_discord_id == guild_id_2

      bans = TestApp.Discord.GuildBan.read!()
      assert length(bans) == 2
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing guild ban instead of creating duplicate" do
      guild_id = 555_666_777
      user_id = 999_888_777

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      user_data = user(%{id: user_id, username: "test_user"})
      {:ok, user_payload} = Payloads.User.new(user_data)

      {:ok, original} =
        TestApp.Discord.guild_ban_from_discord(%{
          data: %{guild_id: guild_id, user: user_payload}
        })

      {:ok, updated} =
        TestApp.Discord.guild_ban_from_discord(%{
          data: %{guild_id: guild_id, user: user_payload}
        })

      assert updated.id == original.id
      assert updated.user_discord_id == original.user_discord_id
      assert updated.guild_discord_id == original.guild_discord_id

      bans = TestApp.Discord.GuildBan.read!()
      assert length(bans) == 1
    end
  end
end
