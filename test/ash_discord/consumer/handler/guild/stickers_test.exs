defmodule AshDiscord.Consumer.Handler.Guild.StickersTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Guild.Stickers
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/3" do
    test "creates stickers from new_stickers list in database" do
      guild_id = generate_snowflake()
      sticker1_data = sticker(%{name: "sticker1"})
      sticker2_data = sticker(%{name: "sticker2"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Sticker,
        guild: nil,
        user: nil
      }

      {:ok, sticker1_payload} = Payloads.Sticker.new(sticker1_data)
      {:ok, sticker2_payload} = Payloads.Sticker.new(sticker2_data)

      guild_stickers_update = %Payloads.GuildStickersUpdate{
        guild_id: guild_id,
        old_stickers: [],
        new_stickers: [sticker1_payload, sticker2_payload]
      }

      assert :ok =
               Stickers.update(
                 guild_stickers_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify stickers were created in database
      stickers = TestApp.Discord.Sticker.read!()
      assert length(stickers) == 2

      sticker_ids = Enum.map(stickers, & &1.discord_id) |> Enum.sort()
      expected_ids = Enum.sort([sticker1_data.id, sticker2_data.id])
      assert sticker_ids == expected_ids

      # Verify sticker attributes
      created_sticker1 = Enum.find(stickers, &(&1.discord_id == sticker1_data.id))
      assert created_sticker1.name == "sticker1"

      created_sticker2 = Enum.find(stickers, &(&1.discord_id == sticker2_data.id))
      assert created_sticker2.name == "sticker2"
    end

    test "updates existing stickers via upsert" do
      guild_id = generate_snowflake()
      old_sticker = sticker(%{name: "old_name"})
      new_sticker = sticker(%{id: old_sticker.id, name: "new_name"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Sticker,
        guild: nil,
        user: nil
      }

      # Create initial sticker
      {:ok, old_sticker_payload} = Payloads.Sticker.new(old_sticker)

      {:ok, _created} =
        TestApp.Discord.Sticker
        |> Ash.Changeset.for_create(:from_discord, %{
          data: old_sticker_payload,
          identity: old_sticker.id
        })
        |> Ash.create()

      # Verify initial state
      stickers_before = TestApp.Discord.Sticker.read!()
      assert length(stickers_before) == 1
      assert hd(stickers_before).name == "old_name"

      # Update via handler
      {:ok, new_sticker_payload} = Payloads.Sticker.new(new_sticker)

      guild_stickers_update = %Payloads.GuildStickersUpdate{
        guild_id: guild_id,
        old_stickers: [old_sticker_payload],
        new_stickers: [new_sticker_payload]
      }

      assert :ok =
               Stickers.update(
                 guild_stickers_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify sticker was updated (not duplicated)
      stickers_after = TestApp.Discord.Sticker.read!()
      assert length(stickers_after) == 1

      updated_sticker = hd(stickers_after)
      assert updated_sticker.discord_id == new_sticker.id
      assert updated_sticker.name == "new_name"
    end

    test "handles empty new_stickers list" do
      guild_id = generate_snowflake()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Sticker,
        guild: nil,
        user: nil
      }

      guild_stickers_update = %Payloads.GuildStickersUpdate{
        guild_id: guild_id,
        old_stickers: [],
        new_stickers: []
      }

      # Should not crash with empty list
      assert :ok =
               Stickers.update(
                 guild_stickers_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify no stickers were created
      stickers = TestApp.Discord.Sticker.read!()
      assert length(stickers) == 0
    end

    test "processes multiple stickers in single update" do
      guild_id = generate_snowflake()
      sticker_count = 5

      sticker_data_list =
        Enum.map(1..sticker_count, fn i ->
          sticker(%{name: "sticker_#{i}"})
        end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Sticker,
        guild: nil,
        user: nil
      }

      sticker_payloads =
        Enum.map(sticker_data_list, fn sticker_data ->
          {:ok, payload} = Payloads.Sticker.new(sticker_data)
          payload
        end)

      guild_stickers_update = %Payloads.GuildStickersUpdate{
        guild_id: guild_id,
        old_stickers: [],
        new_stickers: sticker_payloads
      }

      assert :ok =
               Stickers.update(
                 guild_stickers_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify all stickers were created
      stickers = TestApp.Discord.Sticker.read!()
      assert length(stickers) == sticker_count

      # Verify all names are present
      sticker_names = Enum.map(stickers, & &1.name) |> Enum.sort()
      expected_names = Enum.map(1..sticker_count, &"sticker_#{&1}") |> Enum.sort()
      assert sticker_names == expected_names
    end
  end
end
