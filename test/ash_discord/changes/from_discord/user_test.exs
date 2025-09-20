defmodule AshDiscord.Changes.FromDiscord.UserTest do
  @moduledoc """
  Comprehensive tests for User entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord

  describe "struct-first pattern" do
    test "creates user from discord struct with all attributes" do
      user_struct =
        user(%{
          id: 123_456_789,
          username: "test_user",
          avatar: "avatar_hash_123",
          discriminator: "1234",
          bot: false
        })

      result = TestApp.Discord.user_from_discord(%{discord_struct: user_struct})

      assert {:ok, created_user} = result
      assert created_user.discord_id == user_struct.id
      assert created_user.discord_username == user_struct.username
      assert created_user.discord_avatar == user_struct.avatar
      assert created_user.email == "discord+#{user_struct.id}@discord.local"
    end

    test "handles nil avatar gracefully" do
      user_struct =
        user(%{
          id: 987_654_321,
          username: "no_avatar_user",
          avatar: nil
        })

      result = TestApp.Discord.user_from_discord(%{discord_struct: user_struct})

      assert {:ok, created_user} = result
      assert created_user.discord_id == user_struct.id
      assert created_user.discord_username == user_struct.username
      assert created_user.discord_avatar == nil
      assert created_user.email == "discord+#{user_struct.id}@discord.local"
    end

    test "handles bot users correctly" do
      bot_struct =
        user(%{
          id: 111_222_333,
          username: "test_bot",
          bot: true
        })

      result = TestApp.Discord.user_from_discord(%{discord_struct: bot_struct})

      assert {:ok, created_user} = result
      assert created_user.discord_id == bot_struct.id
      assert created_user.discord_username == bot_struct.username
      assert created_user.email == "discord+#{bot_struct.id}@discord.local"
    end
  end

  describe "API fallback pattern" do
    setup do
      Mimic.copy(Nostrum.Api.User)
      :ok
    end

    test "fetches user from API when discord_struct not provided" do
      discord_id = 999_888_777

      Mimic.expect(Nostrum.Api.User, :get, fn ^discord_id ->
        {:ok, user(%{id: discord_id, username: "api_fetched_user", avatar: "api_avatar"})}
      end)

      result = TestApp.Discord.user_from_discord(%{discord_id: discord_id})

      assert {:ok, created_user} = result
      assert created_user.discord_id == discord_id
      assert created_user.discord_username == "api_fetched_user"
      assert created_user.discord_avatar == "api_avatar"
      assert created_user.email == "discord+#{discord_id}@discord.local"
    end

    test "handles API errors gracefully" do
      discord_id = 404_404_404

      Mimic.expect(Nostrum.Api.User, :get, fn ^discord_id ->
        {:error, %{status_code: 404, message: "User not found"}}
      end)

      result = TestApp.Discord.user_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Failed to fetch user with ID #{discord_id}"
      assert error_message =~ "User not found"
    end

    test "requires discord_id when no discord_struct provided" do
      result = TestApp.Discord.user_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord ID found for user entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing user instead of creating duplicate" do
      discord_id = 555_666_777

      # Create initial user
      initial_struct =
        user(%{
          id: discord_id,
          username: "original_user",
          avatar: "original_avatar"
        })

      {:ok, original_user} = TestApp.Discord.user_from_discord(%{discord_struct: initial_struct})

      # Update same user with new data
      updated_struct =
        user(%{
          # Same ID
          id: discord_id,
          username: "updated_user",
          avatar: "updated_avatar"
        })

      {:ok, updated_user} = TestApp.Discord.user_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_user.id == original_user.id
      assert updated_user.discord_id == original_user.discord_id

      # But with updated attributes
      assert updated_user.discord_username == "updated_user"
      assert updated_user.discord_avatar == "updated_avatar"

    end

    test "upsert works with API fallback" do
      discord_id = 333_444_555

      # Create initial user via struct
      initial_struct =
        user(%{
          id: discord_id,
          username: "struct_user"
        })

      {:ok, original_user} = TestApp.Discord.user_from_discord(%{discord_struct: initial_struct})

      # Update via API fallback
      Mimic.copy(Nostrum.Api.User)

      Mimic.expect(Nostrum.Api.User, :get, fn ^discord_id ->
        {:ok, user(%{id: discord_id, username: "api_updated_user"})}
      end)

      {:ok, updated_user} = TestApp.Discord.user_from_discord(%{discord_id: discord_id})

      # Should be same record
      assert updated_user.id == original_user.id
      assert updated_user.discord_id == discord_id
      assert updated_user.discord_username == "api_updated_user"

    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.user_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = user(%{id: nil, name: nil})

      # This should either return an error or raise an exception
      result =
        try do
          TestApp.Discord.user_from_discord(%{discord_struct: invalid_struct})
        rescue
          error -> {:error, error}
        end

      assert {:error, error} = result
      error_message = Exception.message(error)
      # The error should indicate invalid discord_struct data
      assert error_message =~ "id" or error_message =~ "required" or error_message =~ "invalid"
    end
  end
end
