defmodule AshDiscord.Consumer.Handler.GuildStickersTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.GuildStickers
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/3" do
    @tag :fixed
    test "creates stickers from new_stickers list in database" do
      guild_id = generate_snowflake()
      sticker1_data = sticker(%{name: "sticker1"})
      sticker2_data = sticker(%{name: "sticker2"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Sticker,
        guild: nil,
        user: nil,
        context: %{
          private: %{ash_discord?: true},
          shared: %{private: %{ash_discord?: true}}
        }
      }

      sticker1_payload = Payloads.Sticker.new!(sticker1_data)
      sticker2_payload = Payloads.Sticker.new!(sticker2_data)

      guild_stickers_update = %Payloads.GuildStickersUpdate{
        guild_id: guild_id,
        old_stickers: [],
        new_stickers: [sticker1_payload, sticker2_payload]
      }

      assert :ok =
               GuildStickers.update(
                 guild_stickers_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      stickers = TestApp.Discord.Sticker.read!(authorize?: false)
      assert length(stickers) == 2

      sticker_ids = Enum.map(stickers, & &1.discord_id) |> Enum.sort()
      expected_ids = Enum.sort([sticker1_data.id, sticker2_data.id])
      assert sticker_ids == expected_ids

      created_sticker1 = Enum.find(stickers, &(&1.discord_id == sticker1_data.id))
      assert created_sticker1.name == "sticker1"

      created_sticker2 = Enum.find(stickers, &(&1.discord_id == sticker2_data.id))
      assert created_sticker2.name == "sticker2"
    end

    @tag :fixed
    test "updates existing stickers via upsert" do
      guild_id = generate_snowflake()
      old_sticker = sticker(%{name: "old_name"})
      new_sticker = sticker(%{id: old_sticker.id, name: "new_name"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Sticker,
        guild: nil,
        user: nil,
        context: %{
          private: %{ash_discord?: true},
          shared: %{private: %{ash_discord?: true}}
        }
      }

      old_sticker_payload = Payloads.Sticker.new!(old_sticker)

      TestApp.Discord.sticker_from_discord!(%{data: old_sticker_payload}, authorize?: false)

      [sticker_before] = TestApp.Discord.Sticker.read!(authorize?: false)
      assert sticker_before.name == "old_name"

      new_sticker_payload = Payloads.Sticker.new!(new_sticker)

      guild_stickers_update = %Payloads.GuildStickersUpdate{
        guild_id: guild_id,
        old_stickers: [old_sticker_payload],
        new_stickers: [new_sticker_payload]
      }

      assert :ok =
               GuildStickers.update(
                 guild_stickers_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [updated_sticker] = TestApp.Discord.Sticker.read!(authorize?: false)
      assert updated_sticker.discord_id == new_sticker.id
      assert updated_sticker.name == "new_name"
    end

    @tag :fixed
    test "handles empty new_stickers list" do
      guild_id = generate_snowflake()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Sticker,
        guild: nil,
        user: nil,
        context: %{
          private: %{ash_discord?: true},
          shared: %{private: %{ash_discord?: true}}
        }
      }

      guild_stickers_update = %Payloads.GuildStickersUpdate{
        guild_id: guild_id,
        old_stickers: [],
        new_stickers: []
      }

      assert :ok =
               GuildStickers.update(
                 guild_stickers_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      assert [] = TestApp.Discord.Sticker.read!(authorize?: false)
    end

    @tag :fixed
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
        user: nil,
        context: %{
          private: %{ash_discord?: true},
          shared: %{private: %{ash_discord?: true}}
        }
      }

      sticker_payloads =
        Enum.map(sticker_data_list, fn sticker_data ->
          Payloads.Sticker.new!(sticker_data)
        end)

      guild_stickers_update = %Payloads.GuildStickersUpdate{
        guild_id: guild_id,
        old_stickers: [],
        new_stickers: sticker_payloads
      }

      assert :ok =
               GuildStickers.update(
                 guild_stickers_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      stickers = TestApp.Discord.Sticker.read!(authorize?: false)
      assert length(stickers) == sticker_count

      sticker_names = Enum.map(stickers, & &1.name) |> Enum.sort()
      expected_names = Enum.map(1..sticker_count, &"sticker_#{&1}") |> Enum.sort()
      assert sticker_names == expected_names
    end
  end
end
