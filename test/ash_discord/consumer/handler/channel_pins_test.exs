defmodule AshDiscord.Consumer.Handler.ChannelPinsTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.ChannelPins
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/3" do
    @tag :fixed
    test "creates channel pins update in database" do
      pins_data = channel_pins_update()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ChannelPinsUpdate,
        guild: nil,
        user: nil,
        context: nil
      }

      pins_payload = Payloads.ChannelPinsUpdateEvent.new!(pins_data)

      assert :ok = ChannelPins.update(pins_payload, %Nostrum.Struct.WSState{}, context)

      [created_pins] = TestApp.Discord.ChannelPinsUpdate.read!(authorize?: false)

      assert created_pins.channel_id == pins_data.channel_id
      assert created_pins.guild_id == pins_data.guild_id
      assert created_pins.discord_id == pins_data.channel_id
    end

    @tag :fixed
    test "upserts channel pins update on subsequent calls" do
      channel_id = generate_snowflake()
      guild_id = generate_snowflake()

      first_timestamp = DateTime.utc_now() |> DateTime.add(-3600, :second)
      second_timestamp = DateTime.utc_now()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ChannelPinsUpdate,
        guild: nil,
        user: nil,
        context: nil
      }

      first_pins_data =
        channel_pins_update(%{
          channel_id: channel_id,
          guild_id: guild_id,
          last_pin_timestamp: first_timestamp
        })

      first_payload = Payloads.ChannelPinsUpdateEvent.new!(first_pins_data)
      assert :ok = ChannelPins.update(first_payload, %Nostrum.Struct.WSState{}, context)

      second_pins_data =
        channel_pins_update(%{
          channel_id: channel_id,
          guild_id: guild_id,
          last_pin_timestamp: second_timestamp
        })

      second_payload = Payloads.ChannelPinsUpdateEvent.new!(second_pins_data)
      assert :ok = ChannelPins.update(second_payload, %Nostrum.Struct.WSState{}, context)

      [updated_pins] = TestApp.Discord.ChannelPinsUpdate.read!(authorize?: false)

      assert updated_pins.channel_id == channel_id
      assert updated_pins.guild_id == guild_id

      assert DateTime.diff(updated_pins.last_pin_timestamp, second_timestamp, :second) |> abs() <=
               1
    end

    @tag :fixed
    test "handles pins update without guild_id (DM channels)" do
      pins_data = channel_pins_update(%{guild_id: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ChannelPinsUpdate,
        guild: nil,
        user: nil,
        context: nil
      }

      pins_payload = Payloads.ChannelPinsUpdateEvent.new!(pins_data)

      assert :ok = ChannelPins.update(pins_payload, %Nostrum.Struct.WSState{}, context)

      [created_pins] = TestApp.Discord.ChannelPinsUpdate.read!(authorize?: false)

      assert created_pins.channel_id == pins_data.channel_id
      assert created_pins.guild_id == nil
    end
  end
end
