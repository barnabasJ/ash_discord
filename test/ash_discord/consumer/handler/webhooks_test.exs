defmodule AshDiscord.Consumer.Handler.WebhooksTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Webhooks
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/3" do
    @tag :fixed
    test "creates webhooks update record in database" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      webhooks_update_data =
        webhooks_update_event(%{guild_id: guild_data.id, channel_id: channel_data.id})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      webhooks_update_payload = Payloads.WebhooksUpdateEvent.new!(webhooks_update_data)

      assert :ok =
               Webhooks.update(webhooks_update_payload, %Nostrum.Struct.WSState{}, context)

      [created_record] =
        TestApp.Discord.WebhooksUpdate
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert created_record.guild.discord_id == guild_data.id
      assert created_record.channel.discord_id == channel_data.id
    end

    @tag :fixed
    test "upserts webhooks update for same guild/channel" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      webhooks_update_data_1 =
        webhooks_update_event(%{guild_id: guild_data.id, channel_id: channel_data.id})

      webhooks_update_data_2 =
        webhooks_update_event(%{guild_id: guild_data.id, channel_id: channel_data.id})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      payload_1 = Payloads.WebhooksUpdateEvent.new!(webhooks_update_data_1)
      payload_2 = Payloads.WebhooksUpdateEvent.new!(webhooks_update_data_2)

      assert :ok = Webhooks.update(payload_1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Webhooks.update(payload_2, %Nostrum.Struct.WSState{}, context)

      [updated_record] =
        TestApp.Discord.WebhooksUpdate
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert updated_record.guild.discord_id == guild_data.id
      assert updated_record.channel.discord_id == channel_data.id
    end

    @tag :fixed
    test "handles multiple different guild/channel combinations" do
      guild_data_1 = guild()
      channel_data_1 = channel(%{guild_id: guild_data_1.id})
      guild_data_2 = guild()
      channel_data_2 = channel(%{guild_id: guild_data_2.id})

      TestApp.Discord.guild_from_discord!(%{data: guild_data_1}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data_1}, authorize?: false)
      TestApp.Discord.guild_from_discord!(%{data: guild_data_2}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data_2}, authorize?: false)

      webhooks_update_data_1 =
        webhooks_update_event(%{guild_id: guild_data_1.id, channel_id: channel_data_1.id})

      webhooks_update_data_2 =
        webhooks_update_event(%{guild_id: guild_data_2.id, channel_id: channel_data_2.id})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      payload_1 = Payloads.WebhooksUpdateEvent.new!(webhooks_update_data_1)
      payload_2 = Payloads.WebhooksUpdateEvent.new!(webhooks_update_data_2)

      assert :ok = Webhooks.update(payload_1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Webhooks.update(payload_2, %Nostrum.Struct.WSState{}, context)

      webhooks_update_records =
        TestApp.Discord.WebhooksUpdate
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert length(webhooks_update_records) == 2

      guild_ids = Enum.map(webhooks_update_records, & &1.guild.discord_id)
      assert guild_data_1.id in guild_ids
      assert guild_data_2.id in guild_ids
    end

    @tag :fixed
    test "handles different channels in same guild" do
      guild_data = guild()
      channel_data_1 = channel(%{guild_id: guild_data.id})
      channel_data_2 = channel(%{guild_id: guild_data.id})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data_1}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data_2}, authorize?: false)

      webhooks_update_data_1 =
        webhooks_update_event(%{guild_id: guild_data.id, channel_id: channel_data_1.id})

      webhooks_update_data_2 =
        webhooks_update_event(%{guild_id: guild_data.id, channel_id: channel_data_2.id})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      payload_1 = Payloads.WebhooksUpdateEvent.new!(webhooks_update_data_1)
      payload_2 = Payloads.WebhooksUpdateEvent.new!(webhooks_update_data_2)

      assert :ok = Webhooks.update(payload_1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Webhooks.update(payload_2, %Nostrum.Struct.WSState{}, context)

      webhooks_update_records =
        TestApp.Discord.WebhooksUpdate
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert length(webhooks_update_records) == 2

      Enum.each(webhooks_update_records, fn record ->
        assert record.guild.discord_id == guild_data.id
      end)

      channel_ids = Enum.map(webhooks_update_records, & &1.channel.discord_id)
      assert channel_data_1.id in channel_ids
      assert channel_data_2.id in channel_ids
    end

    @tag :fixed
    test "accepts map with atom keys" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      webhooks_update_data = %{
        guild_id: guild_data.id,
        channel_id: channel_data.id
      }

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      webhooks_update_payload = Payloads.WebhooksUpdateEvent.new!(webhooks_update_data)

      assert :ok =
               Webhooks.update(webhooks_update_payload, %Nostrum.Struct.WSState{}, context)

      [created_record] =
        TestApp.Discord.WebhooksUpdate
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert created_record.guild.discord_id == guild_data.id
      assert created_record.channel.discord_id == channel_data.id
    end

    @tag :fixed
    test "accepts map with string keys" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      webhooks_update_data = %{
        "guild_id" => guild_data.id,
        "channel_id" => channel_data.id
      }

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.WebhooksUpdate,
        guild: nil,
        user: nil
      }

      webhooks_update_payload = Payloads.WebhooksUpdateEvent.new!(webhooks_update_data)

      assert :ok =
               Webhooks.update(webhooks_update_payload, %Nostrum.Struct.WSState{}, context)

      [created_record] =
        TestApp.Discord.WebhooksUpdate
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert created_record.guild.discord_id == guild_data.id
      assert created_record.channel.discord_id == channel_data.id
    end
  end
end
