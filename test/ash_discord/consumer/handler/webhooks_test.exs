defmodule AshDiscord.Consumer.Handler.WebhooksTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Webhooks
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/3" do
    test "creates webhooks update record in database" do
      webhooks_update_data = webhooks_update_event()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      {:ok, webhooks_update_payload} = Payloads.WebhooksUpdateEvent.new(webhooks_update_data)

      assert :ok =
               Webhooks.update(webhooks_update_payload, %Nostrum.Struct.WSState{}, context)

      # Verify webhooks update event was recorded
      webhooks_update_records = TestApp.Discord.WebhooksUpdate.read!()
      assert length(webhooks_update_records) == 1

      created_record = hd(webhooks_update_records)
      assert created_record.guild_id == webhooks_update_data.guild_id
      assert created_record.channel_id == webhooks_update_data.channel_id
    end

    test "upserts webhooks update for same guild/channel" do
      guild_id = generate_snowflake()
      channel_id = generate_snowflake()

      webhooks_update_data_1 =
        webhooks_update_event(%{guild_id: guild_id, channel_id: channel_id})

      webhooks_update_data_2 =
        webhooks_update_event(%{guild_id: guild_id, channel_id: channel_id})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      {:ok, payload_1} = Payloads.WebhooksUpdateEvent.new(webhooks_update_data_1)
      {:ok, payload_2} = Payloads.WebhooksUpdateEvent.new(webhooks_update_data_2)

      # Create initial record
      assert :ok = Webhooks.update(payload_1, %Nostrum.Struct.WSState{}, context)

      # Update with same guild/channel (simulates repeated webhook changes)
      assert :ok = Webhooks.update(payload_2, %Nostrum.Struct.WSState{}, context)

      # Should only have one record due to upsert
      webhooks_update_records = TestApp.Discord.WebhooksUpdate.read!()
      assert length(webhooks_update_records) == 1

      updated_record = hd(webhooks_update_records)
      assert updated_record.guild_id == guild_id
      assert updated_record.channel_id == channel_id
    end

    test "handles multiple different guild/channel combinations" do
      guild_id_1 = generate_snowflake()
      channel_id_1 = generate_snowflake()
      guild_id_2 = generate_snowflake()
      channel_id_2 = generate_snowflake()

      webhooks_update_data_1 =
        webhooks_update_event(%{guild_id: guild_id_1, channel_id: channel_id_1})

      webhooks_update_data_2 =
        webhooks_update_event(%{guild_id: guild_id_2, channel_id: channel_id_2})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      {:ok, payload_1} = Payloads.WebhooksUpdateEvent.new(webhooks_update_data_1)
      {:ok, payload_2} = Payloads.WebhooksUpdateEvent.new(webhooks_update_data_2)

      # Create records for different guild/channel combinations
      assert :ok = Webhooks.update(payload_1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Webhooks.update(payload_2, %Nostrum.Struct.WSState{}, context)

      # Should have two separate records
      webhooks_update_records = TestApp.Discord.WebhooksUpdate.read!()
      assert length(webhooks_update_records) == 2

      guild_ids = Enum.map(webhooks_update_records, & &1.guild_id)
      assert guild_id_1 in guild_ids
      assert guild_id_2 in guild_ids
    end

    test "handles different channels in same guild" do
      guild_id = generate_snowflake()
      channel_id_1 = generate_snowflake()
      channel_id_2 = generate_snowflake()

      webhooks_update_data_1 =
        webhooks_update_event(%{guild_id: guild_id, channel_id: channel_id_1})

      webhooks_update_data_2 =
        webhooks_update_event(%{guild_id: guild_id, channel_id: channel_id_2})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      {:ok, payload_1} = Payloads.WebhooksUpdateEvent.new(webhooks_update_data_1)
      {:ok, payload_2} = Payloads.WebhooksUpdateEvent.new(webhooks_update_data_2)

      # Create records for different channels in same guild
      assert :ok = Webhooks.update(payload_1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Webhooks.update(payload_2, %Nostrum.Struct.WSState{}, context)

      # Should have two separate records (different channels)
      webhooks_update_records = TestApp.Discord.WebhooksUpdate.read!()
      assert length(webhooks_update_records) == 2

      # Both should have same guild_id
      Enum.each(webhooks_update_records, fn record ->
        assert record.guild_id == guild_id
      end)

      # But different channel_ids
      channel_ids = Enum.map(webhooks_update_records, & &1.channel_id)
      assert channel_id_1 in channel_ids
      assert channel_id_2 in channel_ids
    end

    test "accepts map with atom keys" do
      webhooks_update_data = %{
        guild_id: generate_snowflake(),
        channel_id: generate_snowflake()
      }

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      {:ok, webhooks_update_payload} = Payloads.WebhooksUpdateEvent.new(webhooks_update_data)

      assert :ok =
               Webhooks.update(webhooks_update_payload, %Nostrum.Struct.WSState{}, context)

      # Verify event was recorded
      webhooks_update_records = TestApp.Discord.WebhooksUpdate.read!()
      assert length(webhooks_update_records) == 1

      created_record = hd(webhooks_update_records)
      assert created_record.guild_id == webhooks_update_data.guild_id
      assert created_record.channel_id == webhooks_update_data.channel_id
    end

    test "accepts map with string keys" do
      guild_id = generate_snowflake()
      channel_id = generate_snowflake()

      webhooks_update_data = %{
        "guild_id" => guild_id,
        "channel_id" => channel_id
      }

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      {:ok, webhooks_update_payload} = Payloads.WebhooksUpdateEvent.new(webhooks_update_data)

      assert :ok =
               Webhooks.update(webhooks_update_payload, %Nostrum.Struct.WSState{}, context)

      # Verify event was recorded
      webhooks_update_records = TestApp.Discord.WebhooksUpdate.read!()
      assert length(webhooks_update_records) == 1

      created_record = hd(webhooks_update_records)
      assert created_record.guild_id == guild_id
      assert created_record.channel_id == channel_id
    end
  end
end
