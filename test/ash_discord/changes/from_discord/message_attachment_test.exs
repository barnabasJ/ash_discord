defmodule AshDiscord.Changes.FromDiscord.MessageAttachmentTest do
  @moduledoc """
  Comprehensive tests for MessageAttachment entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
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
        TestApp.Discord.message_attachment_from_discord(%{data: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.filename == attachment_struct.filename
      assert created_attachment.size == attachment_struct.size
      assert created_attachment.url == attachment_struct.url
      assert created_attachment.proxy_url == attachment_struct.proxy_url
      assert created_attachment.height == attachment_struct.height
      assert created_attachment.width == attachment_struct.width
    end

    @tag :fixed
    test "handles text file attachment" do
      attachment_struct =
        message_attachment(%{
          id: 987_654_321,
          filename: "data.txt",
          size: 2048,
          url: "https://cdn.discordapp.com/attachments/789/012/data.txt",
          proxy_url: "https://media.discordapp.net/attachments/789/012/data.txt",
          height: nil,
          width: nil
        })

      result =
        TestApp.Discord.message_attachment_from_discord(%{data: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.filename == attachment_struct.filename
      assert created_attachment.size == attachment_struct.size
      assert created_attachment.url == attachment_struct.url
      assert created_attachment.proxy_url == attachment_struct.proxy_url
      assert created_attachment.height == nil
      assert created_attachment.width == nil
    end

    @tag :fixed
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
        TestApp.Discord.message_attachment_from_discord(%{data: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.filename == attachment_struct.filename
      assert created_attachment.size == attachment_struct.size
      assert created_attachment.url == attachment_struct.url
      assert created_attachment.proxy_url == attachment_struct.proxy_url
      assert created_attachment.height == 720
      assert created_attachment.width == 1280
    end

    @tag :fixed
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
        TestApp.Discord.message_attachment_from_discord(%{data: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.filename == attachment_struct.filename
      assert created_attachment.height == 600
      assert created_attachment.width == 800
    end

    @tag :fixed
    test "handles large attachment" do
      attachment_struct =
        message_attachment(%{
          id: 999_111_222,
          filename: "large_video.mov",
          size: 26_214_400,
          url: "https://cdn.discordapp.com/attachments/123/789/large_video.mov",
          proxy_url: "https://media.discordapp.net/attachments/123/789/large_video.mov",
          height: 1080,
          width: 1920
        })

      result =
        TestApp.Discord.message_attachment_from_discord(%{data: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.size == 26_214_400
      assert created_attachment.filename == "large_video.mov"
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches attachment from API when data not provided" do
      channel_id = 555_666_777
      message_id = 999_888_777
      attachment_id = 123_456_789

      Mimic.expect(Nostrum.Api.Message, :get, fn ^channel_id, ^message_id ->
        {:ok,
         message(%{
           id: message_id,
           channel_id: channel_id,
           content: "Check out this image!",
           attachments: [
             message_attachment(%{
               id: attachment_id,
               filename: "api_fetched.png",
               size: 2_048_576,
               url: "https://cdn.discordapp.com/attachments/555/999/api_fetched.png",
               proxy_url: "https://media.discordapp.net/attachments/555/999/api_fetched.png",
               height: 1920,
               width: 1080
             }),
             message_attachment(%{id: 987_654_321, filename: "other.jpg"})
           ]
         })}
      end)

      result =
        TestApp.Discord.message_attachment_from_discord(%{
          identity: %{
            channel_id: channel_id,
            message_id: message_id,
            attachment_id: attachment_id
          }
        })

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_id
      assert created_attachment.filename == "api_fetched.png"
      assert created_attachment.size == 2_048_576
      assert created_attachment.height == 1920
      assert created_attachment.width == 1080
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing message attachment instead of creating duplicate" do
      discord_id = 555_666_777

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
        TestApp.Discord.message_attachment_from_discord(%{data: initial_struct})

      updated_struct =
        message_attachment(%{
          id: discord_id,
          filename: "updated.png",
          size: 2048,
          url: "https://cdn.discordapp.com/attachments/111/222/updated.png",
          proxy_url: "https://media.discordapp.net/attachments/111/222/updated.png",
          height: 200,
          width: 200
        })

      {:ok, updated_attachment} =
        TestApp.Discord.message_attachment_from_discord(%{data: updated_struct})

      assert updated_attachment.id == original_attachment.id
      assert updated_attachment.discord_id == original_attachment.discord_id
      assert updated_attachment.filename == "updated.png"
      assert updated_attachment.size == 2048
      assert updated_attachment.height == 200
      assert updated_attachment.width == 200
    end

    @tag :fixed
    test "upsert works with dimension changes" do
      discord_id = 333_444_555

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
        TestApp.Discord.message_attachment_from_discord(%{data: initial_struct})

      updated_struct =
        message_attachment(%{
          id: discord_id,
          filename: "status_test.jpg",
          size: 4096,
          url: "https://cdn.discordapp.com/attachments/444/555/status_test.jpg",
          proxy_url: "https://media.discordapp.net/attachments/444/555/status_test.jpg",
          height: 600,
          width: 800
        })

      {:ok, updated_attachment} =
        TestApp.Discord.message_attachment_from_discord(%{data: updated_struct})

      assert updated_attachment.id == original_attachment.id
      assert updated_attachment.discord_id == discord_id
      assert updated_attachment.height == 600
      assert updated_attachment.width == 800
    end
  end
end
