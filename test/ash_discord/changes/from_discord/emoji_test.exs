defmodule AshDiscord.Changes.FromDiscord.EmojiTest do
  @moduledoc """
  Comprehensive tests for Emoji entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates emoji from discord struct with all attributes" do
      guild_id = 555_666_777

      emoji_struct =
        emoji(%{
          id: 123_456_789,
          name: "custom_emoji",
          animated: false,
          managed: false,
          require_colons: true
        })

      result =
        TestApp.Discord.emoji_from_discord(%{
          data: emoji_struct,
          identity: %{guild_id: guild_id}
        })

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_struct.id
      assert created_emoji.name == emoji_struct.name
      assert created_emoji.animated == false
      assert created_emoji.managed == false
      assert created_emoji.require_colons == true
      assert created_emoji.guild_discord_id == guild_id
    end

    @tag :fixed
    test "handles animated emoji" do
      guild_id = 111_222_333

      emoji_struct =
        emoji(%{
          id: 987_654_321,
          name: "animated_emoji",
          animated: true,
          managed: false,
          require_colons: true
        })

      result =
        TestApp.Discord.emoji_from_discord(%{
          data: emoji_struct,
          identity: %{guild_id: guild_id}
        })

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_struct.id
      assert created_emoji.name == emoji_struct.name
      assert created_emoji.animated == true
      assert created_emoji.guild_discord_id == guild_id
    end

    @tag :fixed
    test "handles managed emoji (from integration)" do
      guild_id = 999_888_777

      emoji_struct =
        emoji(%{
          id: 111_222_333,
          name: "twitch_emoji",
          animated: false,
          managed: true,
          require_colons: true
        })

      result =
        TestApp.Discord.emoji_from_discord(%{
          data: emoji_struct,
          identity: %{guild_id: guild_id}
        })

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_struct.id
      assert created_emoji.name == emoji_struct.name
      assert created_emoji.managed == true
      assert created_emoji.guild_discord_id == guild_id
    end

    @tag :fixed
    test "handles emoji without require_colons" do
      guild_id = 333_444_555

      emoji_struct =
        emoji(%{
          id: 333_444_555,
          name: "special_emoji",
          animated: false,
          managed: false,
          require_colons: false
        })

      result =
        TestApp.Discord.emoji_from_discord(%{
          data: emoji_struct,
          identity: %{guild_id: guild_id}
        })

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_struct.id
      assert created_emoji.name == emoji_struct.name
      assert created_emoji.require_colons == false
      assert created_emoji.guild_discord_id == guild_id
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches emoji from API when data not provided" do
      guild_id = 555_666_777
      emoji_id = 999_888_777

      Mimic.expect(Nostrum.Api.Guild, :emoji, fn ^guild_id, ^emoji_id ->
        {:ok,
         emoji(%{
           id: emoji_id,
           name: "api_fetched_emoji",
           animated: true,
           managed: false,
           require_colons: true
         })}
      end)

      result =
        TestApp.Discord.emoji_from_discord(%{identity: %{guild_id: guild_id, emoji_id: emoji_id}})

      assert {:ok, created_emoji} = result
      assert created_emoji.discord_id == emoji_id
      assert created_emoji.guild_discord_id == guild_id
      assert created_emoji.name == "api_fetched_emoji"
      assert created_emoji.animated == true
      assert created_emoji.custom == true
      assert created_emoji.managed == false
      assert created_emoji.require_colons == true
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing emoji instead of creating duplicate" do
      discord_id = 555_666_777
      guild_id = 111_222_333

      initial_struct =
        emoji(%{
          id: discord_id,
          name: "original_emoji",
          animated: false,
          managed: false
        })

      {:ok, original_emoji} =
        TestApp.Discord.emoji_from_discord(%{
          data: initial_struct,
          identity: %{guild_id: guild_id}
        })

      updated_struct =
        emoji(%{
          id: discord_id,
          name: "updated_emoji",
          animated: true,
          managed: true,
          require_colons: false
        })

      {:ok, updated_emoji} =
        TestApp.Discord.emoji_from_discord(%{
          data: updated_struct,
          identity: %{guild_id: guild_id}
        })

      assert updated_emoji.id == original_emoji.id
      assert updated_emoji.discord_id == original_emoji.discord_id
      assert updated_emoji.guild_discord_id == original_emoji.guild_discord_id

      assert updated_emoji.name == "updated_emoji"
      assert updated_emoji.animated == true
      assert updated_emoji.managed == true
      assert updated_emoji.require_colons == false
    end
  end
end
