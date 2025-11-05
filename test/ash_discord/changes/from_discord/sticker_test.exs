defmodule AshDiscord.Changes.FromDiscord.StickerTest do
  @moduledoc """
  Comprehensive tests for Sticker entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates sticker from discord struct with all attributes" do
      guild_id = 555_666_777

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      sticker_struct =
        sticker(%{
          id: 123_456_789,
          name: "test_sticker",
          description: "A test sticker for unit tests",
          tags: "test,unit,discord",
          type: :guild,
          format_type: :png,
          available: true,
          guild_id: guild_id
        })

      created_sticker =
        TestApp.Discord.sticker_from_discord!(%{data: sticker_struct}, load: [:guild])

      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.name == sticker_struct.name
      assert created_sticker.description == sticker_struct.description
      assert created_sticker.tags == sticker_struct.tags
      assert created_sticker.type == 2
      assert created_sticker.format_type == 1
      assert created_sticker.available == true
      assert created_sticker.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles standard Discord sticker" do
      sticker_struct =
        sticker(%{
          id: 987_654_321,
          name: "discord_standard",
          description: "A standard Discord sticker",
          tags: "discord,standard,official",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: nil
        })

      created_sticker = TestApp.Discord.sticker_from_discord!(%{data: sticker_struct})

      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.name == sticker_struct.name
      assert created_sticker.type == 1
      assert created_sticker.guild_discord_id == nil
    end

    @tag :fixed
    test "handles PNG format sticker" do
      guild_id = 777_888_999

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      sticker_struct =
        sticker(%{
          id: 111_222_333,
          name: "png_sticker",
          description: "A PNG format sticker",
          tags: "image,png",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: guild_id
        })

      created_sticker =
        TestApp.Discord.sticker_from_discord!(%{data: sticker_struct}, load: [:guild])

      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.format_type == 1
      assert created_sticker.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles APNG format sticker" do
      guild_id = 333_444_555

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      sticker_struct =
        sticker(%{
          id: 777_888_999,
          name: "apng_sticker",
          description: "An animated PNG sticker",
          tags: "animated,apng",
          type: :standard,
          format_type: :apng,
          available: true,
          guild_id: guild_id
        })

      created_sticker =
        TestApp.Discord.sticker_from_discord!(%{data: sticker_struct}, load: [:guild])

      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.format_type == 2
      assert created_sticker.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles Lottie format sticker" do
      guild_id = 999_111_222

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      sticker_struct =
        sticker(%{
          id: 333_444_555,
          name: "lottie_sticker",
          description: "A Lottie animated sticker",
          tags: "lottie,animation,vector",
          type: :standard,
          format_type: :lottie,
          available: true,
          guild_id: guild_id
        })

      created_sticker =
        TestApp.Discord.sticker_from_discord!(%{data: sticker_struct}, load: [:guild])

      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.format_type == 3
      assert created_sticker.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles unavailable sticker" do
      guild_id = 222_333_444

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      sticker_struct =
        sticker(%{
          id: 999_111_222,
          name: "unavailable_sticker",
          description: "A sticker that is unavailable",
          tags: "unavailable,test",
          type: :standard,
          format_type: :png,
          available: false,
          guild_id: guild_id
        })

      created_sticker =
        TestApp.Discord.sticker_from_discord!(%{data: sticker_struct}, load: [:guild])

      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.available == false
      assert created_sticker.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles sticker without description" do
      guild_id = 666_777_888

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      sticker_struct =
        sticker(%{
          id: 444_555_666,
          name: "no_description",
          description: nil,
          tags: "minimal",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: guild_id
        })

      created_sticker =
        TestApp.Discord.sticker_from_discord!(%{data: sticker_struct}, load: [:guild])

      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.description == nil
      assert created_sticker.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles sticker with empty tags" do
      guild_id = 888_999_111

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      sticker_struct =
        sticker(%{
          id: 666_777_888,
          name: "no_tags",
          description: "A sticker without tags",
          tags: "",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: guild_id
        })

      created_sticker =
        TestApp.Discord.sticker_from_discord!(%{data: sticker_struct}, load: [:guild])

      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.tags == nil
      assert created_sticker.guild.discord_id == guild_id
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches sticker from API when data not provided" do
      sticker_id = 999_888_777
      guild_id = 555_666_777

      Mimic.expect(Nostrum.Api.Sticker, :get, fn ^sticker_id ->
        {:ok,
         sticker(%{
           id: sticker_id,
           name: "api_fetched_sticker",
           description: "Fetched from API",
           tags: "api,test",
           type: :guild,
           format_type: :png,
           available: true,
           guild_id: guild_id
         })}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      created_sticker =
        TestApp.Discord.sticker_from_discord!(%{identity: sticker_id}, load: [:guild])

      assert created_sticker.discord_id == sticker_id
      assert created_sticker.name == "api_fetched_sticker"
      assert created_sticker.description == "Fetched from API"
      assert created_sticker.tags == "api,test"
      assert created_sticker.type == 2
      assert created_sticker.guild.discord_id == guild_id
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing sticker instead of creating duplicate" do
      guild_id = 111_222_333
      discord_id = 555_666_777

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      initial_struct =
        sticker(%{
          id: discord_id,
          name: "original_sticker",
          description: "Original description",
          tags: "original,tags",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: guild_id
        })

      original_sticker =
        TestApp.Discord.sticker_from_discord!(%{data: initial_struct}, load: [:guild])

      updated_struct =
        sticker(%{
          id: discord_id,
          name: "updated_sticker",
          description: "Updated description",
          tags: "updated,tags,new",
          type: :standard,
          format_type: :apng,
          available: false,
          guild_id: guild_id
        })

      updated_sticker =
        TestApp.Discord.sticker_from_discord!(%{data: updated_struct}, load: [:guild])

      assert updated_sticker.id == original_sticker.id
      assert updated_sticker.discord_id == original_sticker.discord_id
      assert updated_sticker.name == "updated_sticker"
      assert updated_sticker.description == "Updated description"
      assert updated_sticker.tags == "updated,tags,new"
      assert updated_sticker.format_type == 2
      assert updated_sticker.available == false
      assert updated_sticker.guild.discord_id == guild_id
    end

    @tag :fixed
    test "upsert works with availability changes" do
      guild_id = 777_888_999
      discord_id = 333_444_555

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      initial_struct =
        sticker(%{
          id: discord_id,
          name: "status_sticker",
          description: "Status test sticker",
          tags: "status,test",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: guild_id
        })

      original_sticker =
        TestApp.Discord.sticker_from_discord!(%{data: initial_struct}, load: [:guild])

      updated_struct =
        sticker(%{
          id: discord_id,
          name: "status_sticker",
          description: "Status test sticker",
          tags: "status,test",
          type: :standard,
          format_type: :png,
          available: false,
          guild_id: guild_id
        })

      updated_sticker =
        TestApp.Discord.sticker_from_discord!(%{data: updated_struct}, load: [:guild])

      assert updated_sticker.id == original_sticker.id
      assert updated_sticker.discord_id == discord_id
      assert updated_sticker.available == false
      assert updated_sticker.guild.discord_id == guild_id
    end
  end
end
