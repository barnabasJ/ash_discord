defmodule AshDiscord.Changes.FromDiscord.StickerTest do
  @moduledoc """
  Comprehensive tests for Sticker entity from_discord transformation.

  Tests struct-first pattern, API fallback pattern, and upsert behavior.

  Note: Sticker does not create related resources (Guild, User) via from_discord.
  It only stores the foreign key IDs, so tests validate attributes only.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates sticker from discord struct with all attributes" do
      user_id = 999_888_777

      sticker_struct =
        sticker(%{
          id: 123_456_789,
          name: "test_sticker",
          description: "A test sticker for unit tests",
          tags: "test,unit,discord",
          type: :guild,
          format_type: :png,
          available: true,
          guild_id: 555_666_777,
          user: %{id: user_id}
        })

      created = TestApp.Discord.sticker_from_discord!(%{data: sticker_struct})

      assert created.discord_id == sticker_struct.id
      assert created.name == sticker_struct.name
      assert created.description == sticker_struct.description
      assert created.tags == sticker_struct.tags
      assert created.type == 2
      assert created.format_type == 1
      assert created.available == true
      assert created.guild_discord_id == 555_666_777
      assert created.user_discord_id == user_id
    end

    @tag :fixed
    test "handles standard Discord sticker without guild" do
      user_id = 888_777_666

      sticker_struct =
        sticker(%{
          id: 987_654_321,
          name: "discord_standard",
          description: "A standard Discord sticker",
          tags: "discord,standard,official",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: nil,
          user: %{id: user_id}
        })

      created = TestApp.Discord.sticker_from_discord!(%{data: sticker_struct})

      assert created.discord_id == sticker_struct.id
      assert created.name == sticker_struct.name
      assert created.type == 1
      assert created.guild_discord_id == nil
      assert created.user_discord_id == user_id
    end

    @tag :fixed
    test "handles PNG format sticker" do
      sticker_struct =
        sticker(%{
          id: 111_222_333,
          name: "png_sticker",
          description: "A PNG format sticker",
          tags: "image,png",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: 777_888_999,
          user_id: nil
        })

      created = TestApp.Discord.sticker_from_discord!(%{data: sticker_struct})

      assert created.discord_id == sticker_struct.id
      assert created.format_type == 1
      assert created.guild_discord_id == 777_888_999
    end

    @tag :fixed
    test "handles APNG format sticker" do
      sticker_struct =
        sticker(%{
          id: 777_888_999,
          name: "apng_sticker",
          description: "An animated PNG sticker",
          tags: "animated,apng",
          type: :standard,
          format_type: :apng,
          available: true,
          guild_id: 333_444_555,
          user_id: nil
        })

      created = TestApp.Discord.sticker_from_discord!(%{data: sticker_struct})

      assert created.discord_id == sticker_struct.id
      assert created.format_type == 2
      assert created.guild_discord_id == 333_444_555
    end

    @tag :fixed
    test "handles Lottie format sticker" do
      sticker_struct =
        sticker(%{
          id: 333_444_555,
          name: "lottie_sticker",
          description: "A Lottie animated sticker",
          tags: "lottie,animation,vector",
          type: :standard,
          format_type: :lottie,
          available: true,
          guild_id: 999_111_222,
          user_id: nil
        })

      created = TestApp.Discord.sticker_from_discord!(%{data: sticker_struct})

      assert created.discord_id == sticker_struct.id
      assert created.format_type == 3
      assert created.guild_discord_id == 999_111_222
    end

    @tag :fixed
    test "handles unavailable sticker" do
      sticker_struct =
        sticker(%{
          id: 999_111_222,
          name: "unavailable_sticker",
          description: "A sticker that is unavailable",
          tags: "unavailable,test",
          type: :standard,
          format_type: :png,
          available: false,
          guild_id: 222_333_444,
          user_id: nil
        })

      created = TestApp.Discord.sticker_from_discord!(%{data: sticker_struct})

      assert created.discord_id == sticker_struct.id
      assert created.available == false
      assert created.guild_discord_id == 222_333_444
    end

    @tag :fixed
    test "handles sticker without description" do
      sticker_struct =
        sticker(%{
          id: 444_555_666,
          name: "no_description",
          description: nil,
          tags: "minimal",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: 666_777_888,
          user_id: nil
        })

      created = TestApp.Discord.sticker_from_discord!(%{data: sticker_struct})

      assert created.discord_id == sticker_struct.id
      assert created.description == nil
      assert created.guild_discord_id == 666_777_888
    end

    @tag :fixed
    test "handles sticker with empty tags" do
      sticker_struct =
        sticker(%{
          id: 666_777_888,
          name: "no_tags",
          description: "A sticker without tags",
          tags: "",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: 888_999_111,
          user_id: nil
        })

      created = TestApp.Discord.sticker_from_discord!(%{data: sticker_struct})

      assert created.discord_id == sticker_struct.id
      assert created.tags == nil
      assert created.guild_discord_id == 888_999_111
    end

    @tag :fixed
    test "handles sticker without guild or user" do
      sticker_struct =
        sticker(%{
          id: 555_444_333,
          name: "standalone_sticker",
          description: "A sticker without relationships",
          tags: "standalone",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: nil,
          user_id: nil
        })

      created = TestApp.Discord.sticker_from_discord!(%{data: sticker_struct})

      assert created.discord_id == sticker_struct.id
      assert created.name == sticker_struct.name
      assert created.guild_discord_id == nil
      assert created.user_discord_id == nil
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches sticker from API when data not provided" do
      sticker_id = 999_888_777
      user_id = 111_222_333

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
           guild_id: 555_666_777,
           user: %{id: user_id}
         })}
      end)

      created = TestApp.Discord.sticker_from_discord!(%{identity: sticker_id})

      assert created.discord_id == sticker_id
      assert created.name == "api_fetched_sticker"
      assert created.description == "Fetched from API"
      assert created.tags == "api,test"
      assert created.type == 2
      assert created.guild_discord_id == 555_666_777
      assert created.user_discord_id == user_id
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing sticker instead of creating duplicate" do
      discord_id = 555_666_777
      user_id = 444_555_666

      initial_struct =
        sticker(%{
          id: discord_id,
          name: "original_sticker",
          description: "Original description",
          tags: "original,tags",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: 111_222_333,
          user: %{id: user_id}
        })

      original = TestApp.Discord.sticker_from_discord!(%{data: initial_struct})

      updated_struct =
        sticker(%{
          id: discord_id,
          name: "updated_sticker",
          description: "Updated description",
          tags: "updated,tags,new",
          type: :standard,
          format_type: :apng,
          available: false,
          guild_id: 111_222_333,
          user: %{id: user_id}
        })

      updated = TestApp.Discord.sticker_from_discord!(%{data: updated_struct})

      assert updated.id == original.id
      assert updated.discord_id == original.discord_id
      assert updated.name == "updated_sticker"
      assert updated.description == "Updated description"
      assert updated.tags == "updated,tags,new"
      assert updated.format_type == 2
      assert updated.available == false
      assert updated.guild_discord_id == 111_222_333
      assert updated.user_discord_id == user_id
    end

    @tag :fixed
    test "upsert works with availability changes" do
      discord_id = 333_444_555

      initial_struct =
        sticker(%{
          id: discord_id,
          name: "status_sticker",
          description: "Status test sticker",
          tags: "status,test",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: 777_888_999,
          user_id: nil
        })

      original = TestApp.Discord.sticker_from_discord!(%{data: initial_struct})

      updated_struct =
        sticker(%{
          id: discord_id,
          name: "status_sticker",
          description: "Status test sticker",
          tags: "status,test",
          type: :standard,
          format_type: :png,
          available: false,
          guild_id: 777_888_999,
          user_id: nil
        })

      updated = TestApp.Discord.sticker_from_discord!(%{data: updated_struct})

      assert updated.id == original.id
      assert updated.discord_id == discord_id
      assert updated.available == false
      assert updated.guild_discord_id == 777_888_999
    end
  end
end
