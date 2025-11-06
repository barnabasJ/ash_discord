defmodule AshDiscord.Changes.FromDiscord.RoleTest do
  @moduledoc """
  Comprehensive tests for Role entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates role from discord struct with all attributes" do
      guild_id = 555_666_777

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      role_struct =
        role(%{
          id: 123_456_789,
          name: "Test Role",
          color: 16_711_680,
          hoist: true,
          position: 5,
          permissions: 2048,
          managed: false,
          mentionable: true
        })

      created_role =
        TestApp.Discord.role_from_discord!(
          %{
            data: role_struct,
            identity: %{guild_id: guild_id}
          },
          load: [:guild]
        )

      assert created_role.discord_id == role_struct.id
      assert created_role.name == role_struct.name
      assert created_role.color == role_struct.color
      assert created_role.hoist == true
      assert created_role.position == role_struct.position
      assert created_role.permissions == to_string(role_struct.permissions)
      assert created_role.managed == false
      assert created_role.mentionable == true
      assert created_role.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles default role (@everyone)" do
      guild_id = 555_666_777

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      role_struct =
        role(%{
          id: guild_id,
          name: "@everyone",
          color: 0,
          hoist: false,
          position: 0,
          permissions: 104_324_161,
          managed: false,
          mentionable: false
        })

      created_role =
        TestApp.Discord.role_from_discord!(
          %{
            data: role_struct,
            identity: %{guild_id: guild_id}
          },
          load: [:guild]
        )

      assert created_role.discord_id == guild_id
      assert created_role.name == "@everyone"
      assert created_role.color == 0
      assert created_role.hoist == false
      assert created_role.position == 0
      assert created_role.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles managed bot role" do
      guild_id = 111_222_333

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      role_struct =
        role(%{
          id: 777_888_999,
          name: "Bot Role",
          color: 5_793_266,
          hoist: true,
          position: 10,
          permissions: 8,
          managed: true,
          mentionable: false
        })

      created_role =
        TestApp.Discord.role_from_discord!(
          %{
            data: role_struct,
            identity: %{guild_id: guild_id}
          },
          load: [:guild]
        )

      assert created_role.discord_id == role_struct.id
      assert created_role.name == role_struct.name
      assert created_role.managed == true
      assert created_role.mentionable == false
      assert created_role.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles high permission role" do
      guild_id = 999_888_777

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      role_struct =
        role(%{
          id: 333_444_555,
          name: "Admin",
          color: 15_158_332,
          hoist: true,
          position: 20,
          permissions: 8,
          managed: false,
          mentionable: true
        })

      created_role =
        TestApp.Discord.role_from_discord!(
          %{
            data: role_struct,
            identity: %{guild_id: guild_id}
          },
          load: [:guild]
        )

      assert created_role.discord_id == role_struct.id
      assert created_role.name == role_struct.name
      assert created_role.permissions == "8"
      assert created_role.guild.discord_id == guild_id
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches role from API when data not provided" do
      guild_id = 555_666_777
      role_id = 999_888_777

      expect(Nostrum.Api.Guild, :roles, fn ^guild_id ->
        {:ok,
         [
           role(%{
             id: role_id,
             name: "API Fetched Role",
             color: 16_711_680,
             hoist: true,
             position: 10,
             permissions: 2048,
             managed: false,
             mentionable: true
           }),
           role(%{id: 123_456_789, name: "Other Role", permissions: 1024})
         ]}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      created_role =
        TestApp.Discord.role_from_discord!(%{identity: %{guild_id: guild_id, role_id: role_id}},
          load: [:guild]
        )

      assert created_role.discord_id == role_id
      assert created_role.name == "API Fetched Role"
      assert created_role.color == 16_711_680
      assert created_role.hoist == true
      assert created_role.permissions == "2048"
      assert created_role.guild.discord_id == guild_id
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing role instead of creating duplicate" do
      discord_id = 555_666_777
      guild_id = 111_222_333

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      initial_struct =
        role(%{
          id: discord_id,
          name: "Original Role",
          color: 255,
          hoist: false,
          position: 1,
          permissions: 1024
        })

      original_role =
        TestApp.Discord.role_from_discord!(
          %{
            data: initial_struct,
            identity: %{guild_id: guild_id}
          },
          load: [:guild]
        )

      updated_struct =
        role(%{
          id: discord_id,
          name: "Updated Role",
          color: 65_280,
          hoist: true,
          position: 5,
          permissions: 2048,
          mentionable: true
        })

      updated_role =
        TestApp.Discord.role_from_discord!(
          %{
            data: updated_struct,
            identity: %{guild_id: guild_id}
          },
          load: [:guild]
        )

      assert updated_role.id == original_role.id
      assert updated_role.discord_id == original_role.discord_id

      assert updated_role.name == "Updated Role"
      assert updated_role.color == 65_280
      assert updated_role.hoist == true
      assert updated_role.position == 5
      assert updated_role.permissions == "2048"
      assert updated_role.mentionable == true
      assert updated_role.guild.discord_id == guild_id
    end

    @tag :fixed
    test "upsert works with permission changes" do
      discord_id = 333_444_555
      guild_id = 222_333_444

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      initial_struct =
        role(%{
          id: discord_id,
          name: "Member Role",
          permissions: 104_324_161,
          managed: false
        })

      original_role =
        TestApp.Discord.role_from_discord!(
          %{
            data: initial_struct,
            identity: %{guild_id: guild_id}
          },
          load: [:guild]
        )

      updated_struct =
        role(%{
          id: discord_id,
          name: "Member Role",
          permissions: 8,
          managed: false
        })

      updated_role =
        TestApp.Discord.role_from_discord!(
          %{
            data: updated_struct,
            identity: %{guild_id: guild_id}
          },
          load: [:guild]
        )

      assert updated_role.id == original_role.id
      assert updated_role.discord_id == discord_id

      assert updated_role.permissions == "8"
      assert updated_role.guild.discord_id == guild_id
    end
  end
end
