defmodule AshDiscord.Consumer.Handler.ChannelPinsTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.ChannelPins
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/3" do
    @tag :fixed
    test "creates channel pins update in database" do
      guild = guild()
      channel = channel()

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel}, authorize?: false)

      pins_data = channel_pins_update(%{channel_id: channel.id, guild_id: guild.id})

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

      assert created_pins.channel_discord_id == pins_data.channel_id
      assert created_pins.guild_discord_id == pins_data.guild_id
      assert is_struct(created_pins.last_pin_timestamp, DateTime)
    end
  end
end
