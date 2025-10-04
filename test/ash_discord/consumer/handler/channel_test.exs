defmodule AshDiscord.Consumer.Handler.ChannelTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Consumer.Handler.Channel
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/4" do
    test "creates channel in database" do
      channel_data = channel()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      {:ok, channel_payload} = Payloads.Channel.new(channel_data)

      assert :ok = Channel.create(TestConsumer, channel_payload, %Nostrum.Struct.WSState{}, context)

      # Verify channel was created in database
      channels = TestApp.Discord.Channel.read!()
      assert length(channels) == 1

      created_channel = hd(channels)
      assert created_channel.discord_id == channel_data.id
      assert created_channel.name == channel_data.name
    end
  end

  describe "update/4" do
    test "updates existing channel in database" do
      old_channel = channel(%{name: "old-name"})
      new_channel = channel(%{id: old_channel.id, name: "new-name"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      {:ok, old_channel_payload} = Payloads.Channel.new(old_channel)
      {:ok, new_channel_payload} = Payloads.Channel.new(new_channel)

      channel_update = %Payloads.ChannelUpdate{
        old_channel: old_channel_payload,
        new_channel: new_channel_payload
      }

      assert :ok =
               Channel.update(
                 TestConsumer,
                 channel_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify channel was updated (upserted) in database
      channels = TestApp.Discord.Channel.read!()
      assert length(channels) == 1

      updated_channel = hd(channels)
      assert updated_channel.discord_id == new_channel.id
      assert updated_channel.name == "new-name"
    end
  end

  describe "delete/4" do
    test "deletes channel from database" do
      channel_data = channel()

      # First create the channel
      {:ok, channel_payload} = Payloads.Channel.new(channel_data)

      {:ok, _created} =
        TestApp.Discord.Channel
        |> Ash.Changeset.for_create(:from_discord, %{
          data: channel_payload
        })
        |> Ash.create()

      # Verify channel exists
      channels_before = TestApp.Discord.Channel.read!()
      assert length(channels_before) == 1

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Channel.delete(TestConsumer, channel_payload, %Nostrum.Struct.WSState{}, context)

      # Verify channel was deleted from database
      channels_after = TestApp.Discord.Channel.read!()
      assert length(channels_after) == 0
    end

    test "handles missing channel gracefully" do
      channel_data = channel()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      {:ok, channel_payload} = Payloads.Channel.new(channel_data)

      # Should not crash when channel doesn't exist
      assert :ok =
               Channel.delete(TestConsumer, channel_payload, %Nostrum.Struct.WSState{}, context)
    end
  end
end
