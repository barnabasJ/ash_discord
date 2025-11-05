defmodule AshDiscord.Changes.FromDiscord.WebhookTest do
  @moduledoc """
  Comprehensive tests for Webhook entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates webhook from discord struct with all attributes" do
      webhook_struct =
        webhook(%{
          id: 123_456_789,
          name: "Test Webhook",
          channel_id: 555_666_777,
          guild_id: 111_222_333,
          avatar: "webhook_avatar_hash",
          token: "webhook_token_secret"
        })

      created_webhook = TestApp.Discord.webhook_from_discord!(%{data: webhook_struct})

      assert created_webhook.discord_id == webhook_struct.id
      assert created_webhook.name == webhook_struct.name
      assert created_webhook.channel_id == webhook_struct.channel_id
      assert created_webhook.guild_id == webhook_struct.guild_id
      assert created_webhook.avatar == webhook_struct.avatar
      assert created_webhook.token == webhook_struct.token
    end

    @tag :fixed
    test "handles webhook without avatar" do
      webhook_struct =
        webhook(%{
          id: 987_654_321,
          name: "No Avatar Webhook",
          channel_id: 777_888_999,
          guild_id: 333_444_555,
          avatar: nil,
          token: "another_token"
        })

      created_webhook = TestApp.Discord.webhook_from_discord!(%{data: webhook_struct})

      assert created_webhook.discord_id == webhook_struct.id
      assert created_webhook.name == webhook_struct.name
      assert created_webhook.avatar == nil
    end

    @tag :fixed
    test "handles application webhook type" do
      webhook_struct =
        webhook(%{
          id: 111_222_333,
          name: "Application Webhook",
          channel_id: 444_555_666,
          guild_id: 777_888_999,
          avatar: "app_webhook_avatar",
          token: nil
        })

      created_webhook = TestApp.Discord.webhook_from_discord!(%{data: webhook_struct})

      assert created_webhook.discord_id == webhook_struct.id
      assert created_webhook.name == webhook_struct.name
      assert created_webhook.token == nil
    end

    @tag :fixed
    test "handles channel follower webhook" do
      webhook_struct =
        webhook(%{
          id: 777_888_999,
          name: "Channel Follower",
          channel_id: 999_111_222,
          guild_id: 333_444_555,
          avatar: "follower_avatar",
          token: "follower_token"
        })

      created_webhook = TestApp.Discord.webhook_from_discord!(%{data: webhook_struct})

      assert created_webhook.discord_id == webhook_struct.id
      assert created_webhook.name == webhook_struct.name
    end

    @tag :fixed
    test "handles webhook without guild (DM webhook)" do
      webhook_struct =
        webhook(%{
          id: 333_444_555,
          name: "DM Webhook",
          channel_id: 666_777_888,
          guild_id: nil,
          avatar: "dm_avatar",
          token: "dm_token"
        })

      created_webhook = TestApp.Discord.webhook_from_discord!(%{data: webhook_struct})

      assert created_webhook.discord_id == webhook_struct.id
      assert created_webhook.name == webhook_struct.name
      assert created_webhook.guild_id == nil
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches webhook from API when data not provided" do
      webhook_id = 999_888_777

      Mimic.expect(Nostrum.Api.Webhook, :get, fn ^webhook_id ->
        {:ok,
         webhook(%{
           id: webhook_id,
           name: "API Fetched Webhook",
           channel_id: 555_666_777,
           guild_id: 111_222_333,
           avatar: "api_avatar_hash",
           token: "api_token_secret"
         })}
      end)

      created_webhook = TestApp.Discord.webhook_from_discord!(%{identity: webhook_id})

      assert created_webhook.discord_id == webhook_id
      assert created_webhook.name == "API Fetched Webhook"
      assert created_webhook.channel_id == 555_666_777
      assert created_webhook.guild_id == 111_222_333
      assert created_webhook.avatar == "api_avatar_hash"
      assert created_webhook.token == "api_token_secret"
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing webhook instead of creating duplicate" do
      discord_id = 555_666_777

      initial_struct =
        webhook(%{
          id: discord_id,
          name: "Original Webhook",
          channel_id: 111_222_333,
          guild_id: 444_555_666,
          avatar: "original_avatar",
          token: "original_token"
        })

      original_webhook =
        TestApp.Discord.webhook_from_discord!(%{data: initial_struct})

      updated_struct =
        webhook(%{
          id: discord_id,
          name: "Updated Webhook",
          channel_id: 111_222_333,
          guild_id: 444_555_666,
          avatar: "updated_avatar",
          token: "updated_token"
        })

      updated_webhook =
        TestApp.Discord.webhook_from_discord!(%{data: updated_struct})

      assert updated_webhook.id == original_webhook.id
      assert updated_webhook.discord_id == original_webhook.discord_id
      assert updated_webhook.name == "Updated Webhook"
      assert updated_webhook.avatar == "updated_avatar"
      assert updated_webhook.token == "updated_token"
    end

    @tag :fixed
    test "upsert works with type changes" do
      discord_id = 333_444_555

      initial_struct =
        webhook(%{
          id: discord_id,
          name: "Type Change Webhook",
          channel_id: 777_888_999,
          guild_id: 111_222_333,
          token: "type_token"
        })

      original_webhook =
        TestApp.Discord.webhook_from_discord!(%{data: initial_struct})

      updated_struct =
        webhook(%{
          id: discord_id,
          name: "Type Change Webhook",
          channel_id: 777_888_999,
          guild_id: 111_222_333,
          token: nil
        })

      updated_webhook =
        TestApp.Discord.webhook_from_discord!(%{data: updated_struct})

      assert updated_webhook.id == original_webhook.id
      assert updated_webhook.discord_id == discord_id
      assert updated_webhook.token == nil
    end
  end
end
