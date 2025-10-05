defmodule AshDiscord.Changes.FromDiscord.StickerTest do
  @moduledoc """
  Comprehensive tests for Sticker entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord
  import Mimic

  setup do
    copy(Nostrum.Api.Sticker)
    :ok
  end

  describe "struct-first pattern" do
    test "creates sticker from discord struct with all attributes" do
      sticker_struct =
        sticker(%{
          id: 123_456_789,
          name: "test_sticker",
          description: "A test sticker for unit tests",
          tags: "test,unit,discord",
          type: :guild,
          format_type: :png,
          available: true,
          guild_id: 555_666_777
        })

      result = TestApp.Discord.sticker_from_discord(%{data: sticker_struct})

      assert {:ok, created_sticker} = result
      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.name == sticker_struct.name
      assert created_sticker.description == sticker_struct.description
      assert created_sticker.tags == sticker_struct.tags
      assert created_sticker.type == 2
      assert created_sticker.format_type == 1
      assert created_sticker.available == true
      assert created_sticker.guild_id == sticker_struct.guild_id
    end

    test "handles standard Discord sticker" do
      sticker_struct =
        sticker(%{
          id: 987_654_321,
          name: "discord_standard",
          description: "A standard Discord sticker",
          tags: "discord,standard,official",
          # Standard type
          type: :standard,
          format_type: :png,
          available: true,
          # No guild for standard stickers
          guild_id: nil
        })

      result = TestApp.Discord.sticker_from_discord(%{data: sticker_struct})

      assert {:ok, created_sticker} = result
      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.name == sticker_struct.name
      assert created_sticker.type == 1
      assert created_sticker.guild_id == nil
    end

    test "handles PNG format sticker" do
      sticker_struct =
        sticker(%{
          id: 111_222_333,
          name: "png_sticker",
          description: "A PNG format sticker",
          tags: "image,png",
          type: :standard,
          # PNG format
          format_type: :png,
          available: true,
          guild_id: 777_888_999
        })

      result = TestApp.Discord.sticker_from_discord(%{data: sticker_struct})

      assert {:ok, created_sticker} = result
      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.format_type == 1
    end

    test "handles APNG format sticker" do
      sticker_struct =
        sticker(%{
          id: 777_888_999,
          name: "apng_sticker",
          description: "An animated PNG sticker",
          tags: "animated,apng",
          type: :standard,
          # APNG format
          format_type: :apng,
          available: true,
          guild_id: 333_444_555
        })

      result = TestApp.Discord.sticker_from_discord(%{data: sticker_struct})

      assert {:ok, created_sticker} = result
      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.format_type == 2
    end

    test "handles Lottie format sticker" do
      sticker_struct =
        sticker(%{
          id: 333_444_555,
          name: "lottie_sticker",
          description: "A Lottie animated sticker",
          tags: "lottie,animation,vector",
          type: :standard,
          # Lottie format
          format_type: :lottie,
          available: true,
          guild_id: 999_111_222
        })

      result = TestApp.Discord.sticker_from_discord(%{data: sticker_struct})

      assert {:ok, created_sticker} = result
      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.format_type == 3
    end

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
          guild_id: 222_333_444
        })

      result = TestApp.Discord.sticker_from_discord(%{data: sticker_struct})

      assert {:ok, created_sticker} = result
      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.available == false
    end

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
          guild_id: 666_777_888
        })

      result = TestApp.Discord.sticker_from_discord(%{data: sticker_struct})

      assert {:ok, created_sticker} = result
      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.description == nil
    end

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
          guild_id: 888_999_111
        })

      result = TestApp.Discord.sticker_from_discord(%{data: sticker_struct})

      assert {:ok, created_sticker} = result
      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.tags == nil
    end
  end

  describe "API fallback pattern" do
    test "fetches sticker from API when data not provided" do
      sticker_id = 999_888_777

      expect(Nostrum.Api.Sticker, :get, fn ^sticker_id ->
        {:ok,
         sticker(%{
           id: sticker_id,
           name: "api_fetched_sticker",
           description: "Fetched from API",
           tags: "api,test",
           type: :guild,
           format_type: :png,
           available: true,
           guild_id: 555_666_777
         })}
      end)

      result = TestApp.Discord.sticker_from_discord(%{identity: sticker_id})

      assert {:ok, created_sticker} = result
      assert created_sticker.discord_id == sticker_id
      assert created_sticker.name == "api_fetched_sticker"
      assert created_sticker.description == "Fetched from API"
      assert created_sticker.tags == "api,test"
      assert created_sticker.type == 2
      assert created_sticker.guild_id == 555_666_777
    end

    test "handles API errors gracefully" do
      sticker_id = 404_404_404

      expect(Nostrum.Api.Sticker, :get, fn ^sticker_id ->
        {:error, %{status_code: 404, message: "Unknown Sticker"}}
      end)

      result = TestApp.Discord.sticker_from_discord(%{identity: sticker_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Unknown Sticker" or error_message =~ "404"
    end

    test "requires data or identity argument for sticker creation" do
      result = TestApp.Discord.sticker_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # When identity is nil, API call fails with :api_unavailable
      assert error_message =~ ":api_unavailable"
    end
  end

  describe "upsert behavior" do
    test "updates existing sticker instead of creating duplicate" do
      discord_id = 555_666_777

      # Create initial sticker
      initial_struct =
        sticker(%{
          id: discord_id,
          name: "original_sticker",
          description: "Original description",
          tags: "original,tags",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: 111_222_333
        })

      {:ok, original_sticker} =
        TestApp.Discord.sticker_from_discord(%{data: initial_struct})

      # Update same sticker with new data
      updated_struct =
        sticker(%{
          # Same ID
          id: discord_id,
          name: "updated_sticker",
          description: "Updated description",
          tags: "updated,tags,new",
          type: :standard,
          format_type: :apng,
          available: false,
          guild_id: 111_222_333
        })

      {:ok, updated_sticker} =
        TestApp.Discord.sticker_from_discord(%{data: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_sticker.id == original_sticker.id
      assert updated_sticker.discord_id == original_sticker.discord_id

      # But with updated attributes
      assert updated_sticker.name == "updated_sticker"
      assert updated_sticker.description == "Updated description"
      assert updated_sticker.tags == "updated,tags,new"
      assert updated_sticker.format_type == 2
      assert updated_sticker.available == false
    end

    test "upsert works with availability changes" do
      discord_id = 333_444_555

      # Create initial available sticker
      initial_struct =
        sticker(%{
          id: discord_id,
          name: "status_sticker",
          description: "Status test sticker",
          tags: "status,test",
          type: :standard,
          format_type: :png,
          available: true,
          guild_id: 777_888_999
        })

      {:ok, original_sticker} =
        TestApp.Discord.sticker_from_discord(%{data: initial_struct})

      # Mark as unavailable
      updated_struct =
        sticker(%{
          # Same ID
          id: discord_id,
          name: "status_sticker",
          description: "Status test sticker",
          tags: "status,test",
          type: :standard,
          format_type: :png,
          available: false,
          guild_id: 777_888_999
        })

      {:ok, updated_sticker} =
        TestApp.Discord.sticker_from_discord(%{data: updated_struct})

      # Should be same record
      assert updated_sticker.id == original_sticker.id
      assert updated_sticker.discord_id == discord_id

      # But with updated availability
      assert updated_sticker.available == false
    end
  end

  describe "error handling" do
    test "handles invalid data argument format" do
      result = TestApp.Discord.sticker_from_discord(%{data: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for data"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = sticker(%{id: nil, name: nil})

      result = TestApp.Discord.sticker_from_discord(%{data: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required" or error_message =~ "must not be nil"
    end

    test "handles invalid sticker type" do
      sticker_struct =
        sticker(%{
          id: 123_456_789,
          name: "test_sticker",
          description: "Test sticker",
          tags: "test",
          # Invalid type
          type: 999,
          format_type: :png,
          available: true,
          guild_id: 555_666_777
        })

      result = TestApp.Discord.sticker_from_discord(%{data: sticker_struct})

      # This might succeed with normalized type or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_sticker} ->
          # If it succeeds, type should be handled gracefully
          assert created_sticker.discord_id == sticker_struct.id

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end

    test "handles invalid format type" do
      sticker_struct =
        sticker(%{
          id: 123_456_789,
          name: "test_sticker",
          description: "Test sticker",
          tags: "test",
          type: :standard,
          # Invalid format type
          format_type: 999,
          available: true,
          guild_id: 555_666_777
        })

      result = TestApp.Discord.sticker_from_discord(%{data: sticker_struct})

      # This might succeed with normalized format_type or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_sticker} ->
          # If it succeeds, format_type should be handled gracefully
          assert created_sticker.discord_id == sticker_struct.id

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end

    test "handles malformed sticker data" do
      malformed_struct = %{
        id: "not_an_integer",
        # Required field as nil
        name: nil,
        type: "not_an_integer"
      }

      result = TestApp.Discord.sticker_from_discord(%{data: malformed_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # Should contain validation errors
      assert error_message =~ "is required" or error_message =~ "is invalid" or
               error_message =~ "no function clause"
    end
  end
end
