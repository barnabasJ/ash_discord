defmodule AshDiscord.Changes.FromDiscord.UserTest do
  @moduledoc """
  Comprehensive tests for User entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators

  describe "struct-first pattern" do
    @tag :fixed
    test "creates user from discord struct with all attributes" do
      user_struct =
        user(%{
          id: 123_456_789,
          username: "test_user",
          avatar: "avatar_hash_123",
          discriminator: "1234",
          bot: false
        })

      result = TestApp.Discord.user_from_discord(%{data: user_struct})

      assert {:ok, created_user} = result
      assert created_user.discord_id == user_struct.id
      assert created_user.discord_username == user_struct.username
      assert created_user.discord_avatar == user_struct.avatar
      assert created_user.email == "discord+#{user_struct.id}@discord.local"
    end

    @tag :fixed
    test "handles nil avatar gracefully" do
      user_struct =
        user(%{
          id: 987_654_321,
          username: "no_avatar_user",
          avatar: nil
        })

      result = TestApp.Discord.user_from_discord(%{data: user_struct})

      assert {:ok, created_user} = result
      assert created_user.discord_id == user_struct.id
      assert created_user.discord_username == user_struct.username
      assert created_user.discord_avatar == nil
      assert created_user.email == "discord+#{user_struct.id}@discord.local"
    end

    @tag :fixed
    test "handles bot users correctly" do
      bot_struct =
        user(%{
          id: 111_222_333,
          username: "test_bot",
          bot: true
        })

      result = TestApp.Discord.user_from_discord(%{data: bot_struct})

      assert {:ok, created_user} = result
      assert created_user.discord_id == bot_struct.id
      assert created_user.discord_username == bot_struct.username
      assert created_user.email == "discord+#{bot_struct.id}@discord.local"
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches user from API when data not provided" do
      discord_id = 999_888_777

      Mimic.expect(Nostrum.Api.User, :get, fn ^discord_id ->
        {:ok, user(%{id: discord_id, username: "api_fetched_user", avatar: "api_avatar"})}
      end)

      result = TestApp.Discord.user_from_discord(%{identity: discord_id})

      assert {:ok, created_user} = result
      assert created_user.discord_id == discord_id
      assert created_user.discord_username == "api_fetched_user"
      assert created_user.discord_avatar == "api_avatar"
      assert created_user.email == "discord+#{discord_id}@discord.local"
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing user instead of creating duplicate" do
      discord_id = 555_666_777

      initial_struct =
        user(%{
          id: discord_id,
          username: "original_user",
          avatar: "original_avatar"
        })

      {:ok, original_user} = TestApp.Discord.user_from_discord(%{data: initial_struct})

      updated_struct =
        user(%{
          id: discord_id,
          username: "updated_user",
          avatar: "updated_avatar"
        })

      {:ok, updated_user} = TestApp.Discord.user_from_discord(%{data: updated_struct})

      assert updated_user.id == original_user.id
      assert updated_user.discord_id == original_user.discord_id
      assert updated_user.discord_username == "updated_user"
      assert updated_user.discord_avatar == "updated_avatar"
    end
  end
end
