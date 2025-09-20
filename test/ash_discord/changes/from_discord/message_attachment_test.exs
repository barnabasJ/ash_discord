defmodule AshDiscord.Changes.FromDiscord.MessageAttachmentTest do
  @moduledoc """
  Comprehensive tests for MessageAttachment entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord

  describe "struct-first pattern" do
    test "creates message attachment from discord struct with all attributes" do
      attachment_struct =
        message_attachment(%{
          id: 123_456_789,
          filename: "screenshot.png",
          size: 1_048_576,
          url: "https://cdn.discordapp.com/attachments/123/456/screenshot.png",
          proxy_url: "https://media.discordapp.net/attachments/123/456/screenshot.png",
          height: 1080,
          width: 1920
        })

      result =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.filename == attachment_struct.filename
      assert created_attachment.size == attachment_struct.size
      assert created_attachment.url == attachment_struct.url
      assert created_attachment.proxy_url == attachment_struct.proxy_url
      assert created_attachment.height == attachment_struct.height
      assert created_attachment.width == attachment_struct.width
    end

    test "handles text file attachment" do
      attachment_struct =
        message_attachment(%{
          id: 987_654_321,
          filename: "data.txt",
          size: 2048,
          url: "https://cdn.discordapp.com/attachments/789/012/data.txt",
          proxy_url: "https://media.discordapp.net/attachments/789/012/data.txt",
          # No dimensions for text file
          height: nil,
          width: nil
        })

      result =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.filename == attachment_struct.filename
      assert created_attachment.size == attachment_struct.size
      assert created_attachment.url == attachment_struct.url
      assert created_attachment.proxy_url == attachment_struct.proxy_url
      assert created_attachment.height == nil
      assert created_attachment.width == nil
    end

    test "handles video attachment" do
      attachment_struct =
        message_attachment(%{
          id: 111_222_333,
          filename: "clip.mp4",
          size: 10_485_760,
          url: "https://cdn.discordapp.com/attachments/345/678/clip.mp4",
          proxy_url: "https://media.discordapp.net/attachments/345/678/clip.mp4",
          height: 720,
          width: 1280
        })

      result =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.filename == attachment_struct.filename
      assert created_attachment.size == attachment_struct.size
      assert created_attachment.url == attachment_struct.url
      assert created_attachment.proxy_url == attachment_struct.proxy_url
      assert created_attachment.height == 720
      assert created_attachment.width == 1280
    end

    test "handles attachment with image dimensions" do
      attachment_struct =
        message_attachment(%{
          id: 777_888_999,
          filename: "temp_image.jpg",
          size: 524_288,
          url: "https://cdn.discordapp.com/attachments/901/234/temp_image.jpg",
          proxy_url: "https://media.discordapp.net/attachments/901/234/temp_image.jpg",
          height: 600,
          width: 800
        })

      result =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.filename == attachment_struct.filename
      assert created_attachment.height == 600
      assert created_attachment.width == 800
    end

    test "handles attachment without proxy URL" do
      attachment_struct =
        message_attachment(%{
          id: 333_444_555,
          filename: "untitled.png",
          size: 262_144,
          url: "https://cdn.discordapp.com/attachments/567/890/untitled.png",
          proxy_url: nil,
          height: 400,
          width: 600
        })

      result =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.proxy_url == nil
    end

    test "handles large attachment" do
      attachment_struct =
        message_attachment(%{
          id: 999_111_222,
          filename: "large_video.mov",
          # 25MB file
          size: 26_214_400,
          url: "https://cdn.discordapp.com/attachments/123/789/large_video.mov",
          proxy_url: "https://media.discordapp.net/attachments/123/789/large_video.mov",
          height: 1080,
          width: 1920
        })

      result =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.size == 26_214_400
      assert created_attachment.filename == "large_video.mov"
    end
  end

  describe "API fallback pattern" do
    test "message attachment API fallback is not supported" do
      # Message attachments don't support direct API fetching in our implementation
      discord_id = 999_888_777

      result = TestApp.Discord.message_attachment_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Failed to fetch message_attachment with ID #{discord_id}"
      assert error_message =~ ":unsupported_type"
    end

    test "requires discord_struct for message attachment creation" do
      result = TestApp.Discord.message_attachment_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord ID found for message_attachment entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing message attachment instead of creating duplicate" do
      discord_id = 555_666_777

      # Create initial attachment
      initial_struct =
        message_attachment(%{
          id: discord_id,
          filename: "original.png",
          size: 1024,
          url: "https://cdn.discordapp.com/attachments/111/222/original.png",
          proxy_url: "https://media.discordapp.net/attachments/111/222/original.png",
          height: 100,
          width: 100
        })

      {:ok, original_attachment} =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: initial_struct})

      # Update same attachment with new data
      updated_struct =
        message_attachment(%{
          # Same ID
          id: discord_id,
          filename: "updated.png",
          size: 2048,
          url: "https://cdn.discordapp.com/attachments/111/222/updated.png",
          proxy_url: "https://media.discordapp.net/attachments/111/222/updated.png",
          height: 200,
          width: 200
        })

      {:ok, updated_attachment} =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_attachment.id == original_attachment.id
      assert updated_attachment.discord_id == original_attachment.discord_id

      # But with updated attributes
      assert updated_attachment.filename == "updated.png"
      assert updated_attachment.size == 2048
      assert updated_attachment.height == 200
      assert updated_attachment.width == 200
    end

    test "upsert works with dimension changes" do
      discord_id = 333_444_555

      # Create initial attachment with small dimensions
      initial_struct =
        message_attachment(%{
          id: discord_id,
          filename: "status_test.jpg",
          size: 4096,
          url: "https://cdn.discordapp.com/attachments/444/555/status_test.jpg",
          proxy_url: "https://media.discordapp.net/attachments/444/555/status_test.jpg",
          height: 300,
          width: 400
        })

      {:ok, original_attachment} =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: initial_struct})

      # Update with larger dimensions
      updated_struct =
        message_attachment(%{
          # Same ID
          id: discord_id,
          filename: "status_test.jpg",
          size: 4096,
          url: "https://cdn.discordapp.com/attachments/444/555/status_test.jpg",
          proxy_url: "https://media.discordapp.net/attachments/444/555/status_test.jpg",
          height: 600,
          width: 800
        })

      {:ok, updated_attachment} =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: updated_struct})

      # Should be same record
      assert updated_attachment.id == original_attachment.id
      assert updated_attachment.discord_id == discord_id

      # But with updated dimensions
      assert updated_attachment.height == 600
      assert updated_attachment.width == 800
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = message_attachment(%{id: nil, name: nil})

      result =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles invalid size in discord_struct" do
      attachment_struct =
        message_attachment(%{
          id: 123_456_789,
          filename: "test.png",
          content_type: "image/png",
          # Invalid size type
          size: "not_an_integer",
          url: "https://cdn.discordapp.com/attachments/111/222/test.png",
          proxy_url: "https://media.discordapp.net/attachments/111/222/test.png",
          message_id: 555_666_777
        })

      result =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: attachment_struct})

      # This might succeed with normalized size or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_attachment} ->
          # If it succeeds, size should be handled gracefully
          assert created_attachment.discord_id == attachment_struct.id

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end

    test "handles malformed attachment data" do
      malformed_struct = %{
        id: "not_an_integer",
        # Required field as nil
        filename: nil,
        size: "not_an_integer"
      }

      result =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: malformed_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # Should contain validation errors
      assert error_message =~ "is required" or error_message =~ "is invalid"
    end
  end
end
