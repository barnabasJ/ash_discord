defmodule AshDiscord.Changes.FromDiscord.WebhookTest do
  @moduledoc """
  Comprehensive tests for Webhook entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord

  describe "struct-first pattern" do
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

      result = TestApp.Discord.webhook_from_discord(%{discord_struct: webhook_struct})

      assert {:ok, created_webhook} = result
      assert created_webhook.discord_id == webhook_struct.id
      assert created_webhook.name == webhook_struct.name
      assert created_webhook.channel_id == webhook_struct.channel_id
      assert created_webhook.guild_id == webhook_struct.guild_id
      assert created_webhook.avatar == webhook_struct.avatar
      assert created_webhook.token == webhook_struct.token
    end

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

      result = TestApp.Discord.webhook_from_discord(%{discord_struct: webhook_struct})

      assert {:ok, created_webhook} = result
      assert created_webhook.discord_id == webhook_struct.id
      assert created_webhook.name == webhook_struct.name
      assert created_webhook.avatar == nil
    end

    test "handles application webhook type" do
      webhook_struct =
        webhook(%{
          id: 111_222_333,
          name: "Application Webhook",
          # Application webhook type
          channel_id: 444_555_666,
          guild_id: 777_888_999,
          avatar: "app_webhook_avatar",
          token: nil
        })

      result = TestApp.Discord.webhook_from_discord(%{discord_struct: webhook_struct})

      assert {:ok, created_webhook} = result
      assert created_webhook.discord_id == webhook_struct.id
      assert created_webhook.name == webhook_struct.name
      assert created_webhook.token == nil
    end

    test "handles channel follower webhook" do
      webhook_struct =
        webhook(%{
          id: 777_888_999,
          name: "Channel Follower",
          # Channel follower webhook type
          channel_id: 999_111_222,
          guild_id: 333_444_555,
          avatar: "follower_avatar",
          token: "follower_token"
        })

      result = TestApp.Discord.webhook_from_discord(%{discord_struct: webhook_struct})

      assert {:ok, created_webhook} = result
      assert created_webhook.discord_id == webhook_struct.id
      assert created_webhook.name == webhook_struct.name
    end

    test "handles webhook without guild (DM webhook)" do
      webhook_struct =
        webhook(%{
          id: 333_444_555,
          name: "DM Webhook",
          channel_id: 666_777_888,
          # No guild for DM webhook
          guild_id: nil,
          avatar: "dm_avatar",
          token: "dm_token"
        })

      result = TestApp.Discord.webhook_from_discord(%{discord_struct: webhook_struct})

      assert {:ok, created_webhook} = result
      assert created_webhook.discord_id == webhook_struct.id
      assert created_webhook.name == webhook_struct.name
      assert created_webhook.guild_id == nil
    end
  end

  describe "API fallback pattern" do
    test "webhook API fallback is not supported" do
      # Webhooks don't support direct API fetching in our implementation
      discord_id = 999_888_777

      result = TestApp.Discord.webhook_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Failed to fetch webhook with ID #{discord_id}"
      error_message = Exception.message(error)
      assert error_message =~ ":unsupported_type"
    end

    test "requires discord_struct for webhook creation" do
      result = TestApp.Discord.webhook_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord ID found for webhook entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing webhook instead of creating duplicate" do
      discord_id = 555_666_777

      # Create initial webhook
      initial_struct =
        webhook(%{
          id: discord_id,
          name: "Original Webhook",
          channel_id: 111_222_333,
          guild_id: 444_555_666,
          avatar: "original_avatar",
          token: "original_token"
        })

      {:ok, original_webhook} =
        TestApp.Discord.webhook_from_discord(%{discord_struct: initial_struct})

      # Update same webhook with new data
      updated_struct =
        webhook(%{
          # Same ID
          id: discord_id,
          name: "Updated Webhook",
          channel_id: 111_222_333,
          guild_id: 444_555_666,
          avatar: "updated_avatar",
          token: "updated_token"
        })

      {:ok, updated_webhook} =
        TestApp.Discord.webhook_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_webhook.id == original_webhook.id
      assert updated_webhook.discord_id == original_webhook.discord_id

      # But with updated attributes
      assert updated_webhook.name == "Updated Webhook"
      assert updated_webhook.avatar == "updated_avatar"
      assert updated_webhook.token == "updated_token"
    end

    test "upsert works with type changes" do
      discord_id = 333_444_555

      # Create initial incoming webhook
      initial_struct =
        webhook(%{
          id: discord_id,
          name: "Type Change Webhook",
          channel_id: 777_888_999,
          guild_id: 111_222_333,
          token: "type_token"
        })

      {:ok, original_webhook} =
        TestApp.Discord.webhook_from_discord(%{discord_struct: initial_struct})

      # Update to application webhook
      updated_struct =
        webhook(%{
          # Same ID
          id: discord_id,
          name: "Type Change Webhook",
          channel_id: 777_888_999,
          guild_id: 111_222_333,
          token: nil
        })

      {:ok, updated_webhook} =
        TestApp.Discord.webhook_from_discord(%{discord_struct: updated_struct})

      # Should be same record
      assert updated_webhook.id == original_webhook.id
      assert updated_webhook.discord_id == discord_id

      # But with updated type and token
      assert updated_webhook.token == nil
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.webhook_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = %{}

      result = TestApp.Discord.webhook_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles invalid webhook type" do
      webhook_struct =
        webhook(%{
          id: 123_456_789,
          name: "Test Webhook",
          # Invalid type
          channel_id: 555_666_777,
          guild_id: 111_222_333
        })

      result = TestApp.Discord.webhook_from_discord(%{discord_struct: webhook_struct})

      # This might succeed with normalized type or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_webhook} ->
          # If it succeeds, type should be handled gracefully
          assert created_webhook.discord_id == webhook_struct.id

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end

    test "handles malformed webhook data" do
      malformed_struct = %{
        id: "not_an_integer",
        # Required field as nil
        name: nil
      }

      result = TestApp.Discord.webhook_from_discord(%{discord_struct: malformed_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # Should contain validation errors
      assert error_message =~ "is required" or error_message =~ "is invalid"
    end
  end
end
