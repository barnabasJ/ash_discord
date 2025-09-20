defmodule AshDiscord.Changes.FromDiscord.GuildTest do
  @moduledoc """
  Comprehensive tests for Guild entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord

  describe "struct-first pattern" do
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

      result = TestApp.Discord.guild_from_discord(%{discord_struct: guild_struct})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == guild_struct.id
      assert created_guild.name == guild_struct.name
      assert created_guild.description == guild_struct.description
      assert created_guild.icon == guild_struct.icon
    end

    test "handles nil description and icon gracefully" do
      guild_struct =
        guild(%{
          id: 987_654_321,
          name: "Minimal Guild",
          description: nil,
          icon: nil
        })

      result = TestApp.Discord.guild_from_discord(%{discord_struct: guild_struct})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == guild_struct.id
      assert created_guild.name == guild_struct.name
      assert created_guild.description == nil
      assert created_guild.icon == nil
    end

    test "handles large guild with many members" do
      guild_struct =
        guild(%{
          id: 111_222_333,
          name: "Large Guild",
          member_count: 10_000
        })

      result = TestApp.Discord.guild_from_discord(%{discord_struct: guild_struct})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == guild_struct.id
      assert created_guild.name == guild_struct.name
    end
  end

  describe "API fallback pattern" do
    setup do
      Mimic.copy(Nostrum.Api.Guild)
      :ok
    end

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

      result = TestApp.Discord.guild_from_discord(%{discord_id: discord_id})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == discord_id
      assert created_guild.name == "API Fetched Guild"
      assert created_guild.description == "Fetched from Discord API"
      assert created_guild.icon == "api_icon_hash"
    end

    test "handles API errors gracefully" do
      discord_id = 404_404_404

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^discord_id ->
        {:error, %{status_code: 403, message: "Missing Access"}}
      end)

      result = TestApp.Discord.guild_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Failed to fetch guild with ID #{discord_id}"
      error_message = Exception.message(error)
      assert error_message =~ "Missing Access"
    end

    test "requires discord_id when no discord_struct provided" do
      result = TestApp.Discord.guild_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord ID found for guild entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing guild instead of creating duplicate" do
      discord_id = 555_666_777

      # Create initial guild
      initial_struct =
        guild(%{
          id: discord_id,
          name: "Original Guild",
          description: "Original description"
        })

      {:ok, original_guild} =
        TestApp.Discord.guild_from_discord(%{discord_struct: initial_struct})

      # Update same guild with new data
      updated_struct =
        guild(%{
          # Same ID
          id: discord_id,
          name: "Updated Guild",
          description: "Updated description",
          icon: "new_icon_hash"
        })

      {:ok, updated_guild} = TestApp.Discord.guild_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_guild.id == original_guild.id
      assert updated_guild.discord_id == original_guild.discord_id

      # But with updated attributes
      assert updated_guild.name == "Updated Guild"
      assert updated_guild.description == "Updated description"
      assert updated_guild.icon == "new_icon_hash"
    end

    test "upsert works with API fallback" do
      discord_id = 333_444_555

      # Create initial guild via struct
      initial_struct =
        guild(%{
          id: discord_id,
          name: "Struct Guild"
        })

      {:ok, original_guild} =
        TestApp.Discord.guild_from_discord(%{discord_struct: initial_struct})

      # Update via API fallback
      Mimic.copy(Nostrum.Api.Guild)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^discord_id ->
        {:ok,
         guild(%{
           id: discord_id,
           name: "API Updated Guild",
           description: "Updated via API"
         })}
      end)

      {:ok, updated_guild} = TestApp.Discord.guild_from_discord(%{discord_id: discord_id})

      # Should be same record
      assert updated_guild.id == original_guild.id
      assert updated_guild.discord_id == discord_id
      assert updated_guild.name == "API Updated Guild"
      assert updated_guild.description == "Updated via API"
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.guild_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = guild(%{id: nil, name: nil})

      result = TestApp.Discord.guild_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles malformed guild data" do
      malformed_struct =
        guild(%{
          id: "not_an_integer",
          # Required field as nil
          name: nil
        })

      result = TestApp.Discord.guild_from_discord(%{discord_struct: malformed_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # Should contain validation errors
      assert error_message =~ "is required" or error_message =~ "is invalid"
    end
  end
end
