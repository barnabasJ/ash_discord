defmodule AshDiscord.Consumer.Handler.Channel.PinsTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Consumer.Handler.Channel.Pins
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/3" do
    test "creates channel pins update in database" do
      pins_data = channel_pins_update()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ChannelPinsUpdate,
        guild: nil,
        user: nil
      }

      {:ok, pins_payload} = Payloads.ChannelPinsUpdateEvent.new(pins_data)

      assert :ok = Pins.update(pins_payload, %Nostrum.Struct.WSState{}, context)

      # Verify channel pins update was created in database
      pins_updates = TestApp.Discord.ChannelPinsUpdate.read!()
      assert length(pins_updates) == 1

      created_pins = hd(pins_updates)
      assert created_pins.channel_id == pins_data.channel_id
      assert created_pins.guild_id == pins_data.guild_id
      assert created_pins.discord_id == pins_data.channel_id
    end

    test "upserts channel pins update on subsequent calls" do
      channel_id = generate_snowflake()
      guild_id = generate_snowflake()

      first_timestamp = DateTime.utc_now() |> DateTime.add(-3600, :second)
      second_timestamp = DateTime.utc_now()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ChannelPinsUpdate,
        guild: nil,
        user: nil
      }

      # First update
      first_pins_data =
        channel_pins_update(%{
          channel_id: channel_id,
          guild_id: guild_id,
          last_pin_timestamp: first_timestamp
        })

      {:ok, first_payload} = Payloads.ChannelPinsUpdateEvent.new(first_pins_data)
      assert :ok = Pins.update(first_payload, %Nostrum.Struct.WSState{}, context)

      # Second update with new timestamp
      second_pins_data =
        channel_pins_update(%{
          channel_id: channel_id,
          guild_id: guild_id,
          last_pin_timestamp: second_timestamp
        })

      {:ok, second_payload} = Payloads.ChannelPinsUpdateEvent.new(second_pins_data)
      assert :ok = Pins.update(second_payload, %Nostrum.Struct.WSState{}, context)

      # Verify only one record exists with updated timestamp
      pins_updates = TestApp.Discord.ChannelPinsUpdate.read!()
      assert length(pins_updates) == 1

      updated_pins = hd(pins_updates)
      assert updated_pins.channel_id == channel_id
      assert updated_pins.guild_id == guild_id

      # The timestamp should be the second (newer) one (within 1 second tolerance for DateTime precision)
      assert DateTime.diff(updated_pins.last_pin_timestamp, second_timestamp, :second) |> abs() <=
               1
    end

    test "handles pins update without guild_id (DM channels)" do
      pins_data = channel_pins_update(%{guild_id: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.ChannelPinsUpdate,
        guild: nil,
        user: nil
      }

      {:ok, pins_payload} = Payloads.ChannelPinsUpdateEvent.new(pins_data)

      assert :ok = Pins.update(pins_payload, %Nostrum.Struct.WSState{}, context)

      # Verify channel pins update was created
      pins_updates = TestApp.Discord.ChannelPinsUpdate.read!()
      assert length(pins_updates) == 1

      created_pins = hd(pins_updates)
      assert created_pins.channel_id == pins_data.channel_id
      assert created_pins.guild_id == nil
    end
  end
end
