defmodule AshDiscord.Changes.FromDiscord.ChannelPinsUpdateTest do
  @moduledoc """
  Comprehensive tests for ChannelPinsUpdate entity from_discord transformation.

  ChannelPinsUpdate is an ephemeral event and does NOT support API fallback.
  Tests focus on struct-first pattern and error handling.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators.Discord

  describe "struct-first pattern" do
    test "creates channel pins update from discord struct with all attributes" do
      pins_struct =
        channel_pins_update(%{
          channel_id: 123_456_789,
          guild_id: 987_654_321,
          last_pin_timestamp: ~U[2025-01-15 10:30:00Z]
        })

      result = TestApp.Discord.channel_pins_update_from_discord(%{data: pins_struct})

      assert {:ok, created_pins} = result
      assert created_pins.discord_id == pins_struct.channel_id
      assert created_pins.channel_id == pins_struct.channel_id
      assert created_pins.guild_id == pins_struct.guild_id
      assert created_pins.last_pin_timestamp == pins_struct.last_pin_timestamp
    end

    test "handles channel pins update without guild_id (DM channels)" do
      pins_struct =
        channel_pins_update(%{
          channel_id: 111_222_333,
          guild_id: nil,
          last_pin_timestamp: ~U[2025-01-15 11:00:00Z]
        })

      result = TestApp.Discord.channel_pins_update_from_discord(%{data: pins_struct})

      assert {:ok, created_pins} = result
      assert created_pins.channel_id == pins_struct.channel_id
      assert created_pins.guild_id == nil
      assert created_pins.last_pin_timestamp == pins_struct.last_pin_timestamp
    end

    test "handles nil last_pin_timestamp (all pins removed)" do
      pins_struct =
        channel_pins_update(%{
          channel_id: 444_555_666,
          guild_id: 777_888_999,
          last_pin_timestamp: nil
        })

      result = TestApp.Discord.channel_pins_update_from_discord(%{data: pins_struct})

      assert {:ok, created_pins} = result
      assert created_pins.channel_id == pins_struct.channel_id
      assert created_pins.guild_id == pins_struct.guild_id
      assert created_pins.last_pin_timestamp == nil
    end
  end

  describe "data requirement (no API fallback)" do
    test "requires data argument - API fallback not supported for ephemeral events" do
      # ChannelPinsUpdate events are ephemeral and not fetchable from API
      result = TestApp.Discord.channel_pins_update_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)

      assert error_message =~
               "ChannelPinsUpdate requires data argument - pins update events are not fetchable from API"
    end

    test "requires non-nil data argument" do
      result = TestApp.Discord.channel_pins_update_from_discord(%{data: nil})

      assert {:error, error} = result
      error_message = Exception.message(error)

      assert error_message =~
               "ChannelPinsUpdate requires data argument - pins update events are not fetchable from API"
    end
  end

  describe "upsert behavior" do
    test "updates existing channel pins update instead of creating duplicate" do
      channel_id = 555_666_777
      guild_id = 888_999_000

      # Create initial pins update
      initial_struct =
        channel_pins_update(%{
          channel_id: channel_id,
          guild_id: guild_id,
          last_pin_timestamp: ~U[2025-01-15 10:00:00Z]
        })

      {:ok, original_pins} =
        TestApp.Discord.channel_pins_update_from_discord(%{data: initial_struct})

      # Update same channel with new timestamp
      updated_struct =
        channel_pins_update(%{
          # Same channel_id
          channel_id: channel_id,
          guild_id: guild_id,
          last_pin_timestamp: ~U[2025-01-15 12:00:00Z]
        })

      {:ok, updated_pins} =
        TestApp.Discord.channel_pins_update_from_discord(%{data: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_pins.id == original_pins.id
      assert updated_pins.discord_id == original_pins.discord_id
      assert updated_pins.channel_id == channel_id

      # But with updated timestamp
      assert updated_pins.last_pin_timestamp == ~U[2025-01-15 12:00:00Z]
    end

    test "upsert works when guild_id changes (channel moved)" do
      channel_id = 333_444_555

      # Create initial pins update in guild A
      initial_struct =
        channel_pins_update(%{
          channel_id: channel_id,
          guild_id: 111_111_111,
          last_pin_timestamp: ~U[2025-01-15 10:00:00Z]
        })

      {:ok, original_pins} =
        TestApp.Discord.channel_pins_update_from_discord(%{data: initial_struct})

      # Update with different guild (channel moved to guild B)
      updated_struct =
        channel_pins_update(%{
          # Same channel_id
          channel_id: channel_id,
          guild_id: 222_222_222,
          last_pin_timestamp: ~U[2025-01-15 11:00:00Z]
        })

      {:ok, updated_pins} =
        TestApp.Discord.channel_pins_update_from_discord(%{data: updated_struct})

      # Should be same record
      assert updated_pins.id == original_pins.id
      assert updated_pins.discord_id == channel_id

      # But with updated guild_id
      assert updated_pins.guild_id == 222_222_222
      assert updated_pins.last_pin_timestamp == ~U[2025-01-15 11:00:00Z]
    end
  end

  describe "error handling" do
    test "handles invalid data argument format" do
      result = TestApp.Discord.channel_pins_update_from_discord(%{data: "not_a_struct"})

      assert {:error, error} = result
      error_message = Exception.message(error)

      # The error could be from type casting or from the change validation
      assert error_message =~ "Invalid" or
               error_message =~ "expected" or
               error_message =~ "AshDiscord.Consumer.Payloads.ChannelPinsUpdateEvent"
    end

    test "handles missing channel_id in data" do
      # Create an invalid struct missing channel_id
      pins_struct =
        channel_pins_update(%{
          channel_id: nil,
          guild_id: 123_456_789
        })

      result = TestApp.Discord.channel_pins_update_from_discord(%{data: pins_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required" or error_message =~ "must not be nil"
    end
  end
end
