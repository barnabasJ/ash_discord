defmodule AshDiscord.Changes.FromDiscord.GuildTest do
  @moduledoc """
  Comprehensive tests for Guild entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates guild from discord struct with all attributes" do
      guild_struct =
        guild(%{
          id: 123_456_789,
          name: "Test Guild",
          description: "A test guild for testing",
          icon: "guild_icon_hash",
          owner_id: 987_654_321,
          member_count: 42
        })

      result = TestApp.Discord.guild_from_discord(%{data: guild_struct})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == guild_struct.id
      assert created_guild.name == guild_struct.name
      assert created_guild.description == guild_struct.description
      assert created_guild.icon == guild_struct.icon
    end

    @tag :fixed
    test "handles nil description and icon gracefully" do
      guild_struct =
        guild(%{
          id: 987_654_321,
          name: "Minimal Guild",
          description: nil,
          icon: nil
        })

      result = TestApp.Discord.guild_from_discord(%{data: guild_struct})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == guild_struct.id
      assert created_guild.name == guild_struct.name
      assert created_guild.description == nil
      assert created_guild.icon == nil
    end

    @tag :fixed
    test "handles large guild with many members" do
      guild_struct =
        guild(%{
          id: 111_222_333,
          name: "Large Guild",
          member_count: 10_000
        })

      result = TestApp.Discord.guild_from_discord(%{data: guild_struct})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == guild_struct.id
      assert created_guild.name == guild_struct.name
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches guild from API when discord_struct not provided" do
      discord_id = 999_888_777

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^discord_id ->
        {:ok,
         guild(%{
           id: discord_id,
           name: "API Fetched Guild",
           description: "Fetched from Discord API",
           icon: "api_icon_hash"
         })}
      end)

      result = TestApp.Discord.guild_from_discord(%{identity: %{discord_id: discord_id}})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == discord_id
      assert created_guild.name == "API Fetched Guild"
      assert created_guild.description == "Fetched from Discord API"
      assert created_guild.icon == "api_icon_hash"
    end

    @tag :fixed
    test "fetches guild with minimal attributes from API" do
      discord_id = 888_999_000

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^discord_id ->
        {:ok,
         guild(%{
           id: discord_id,
           name: "Minimal API Guild",
           description: nil,
           icon: nil,
           owner_id: nil,
           member_count: nil
         })}
      end)

      result = TestApp.Discord.guild_from_discord(%{identity: %{discord_id: discord_id}})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == discord_id
      assert created_guild.name == "Minimal API Guild"
      assert created_guild.description == nil
      assert created_guild.icon == nil
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing guild instead of creating duplicate" do
      discord_id = 555_666_777

      initial_struct =
        guild(%{
          id: discord_id,
          name: "Original Guild",
          description: "Original description"
        })

      {:ok, original_guild} =
        TestApp.Discord.guild_from_discord(%{data: initial_struct})

      updated_struct =
        guild(%{
          id: discord_id,
          name: "Updated Guild",
          description: "Updated description",
          icon: "new_icon_hash"
        })

      {:ok, updated_guild} = TestApp.Discord.guild_from_discord(%{data: updated_struct})

      assert updated_guild.id == original_guild.id
      assert updated_guild.discord_id == original_guild.discord_id
      assert updated_guild.name == "Updated Guild"
      assert updated_guild.description == "Updated description"
      assert updated_guild.icon == "new_icon_hash"
    end
  end
end
