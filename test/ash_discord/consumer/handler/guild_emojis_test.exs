defmodule AshDiscord.Consumer.Handler.GuildEmojisTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.GuildEmojis
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/3" do
    test "creates emojis from new_emojis list in database" do
      guild_id = generate_snowflake()
      emoji1_data = emoji(%{name: "emoji1"})
      emoji2_data = emoji(%{name: "emoji2"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Emoji,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      {:ok, emoji1_payload} = Payloads.Emoji.new(emoji1_data)
      {:ok, emoji2_payload} = Payloads.Emoji.new(emoji2_data)

      guild_emojis_update = %Payloads.GuildEmojisUpdate{
        guild_id: guild_id,
        old_emojis: [],
        new_emojis: [emoji1_payload, emoji2_payload]
      }

      assert :ok =
               GuildEmojis.update(
                 guild_emojis_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify emojis were created in database
      emojis = TestApp.Discord.Emoji.read!()
      assert length(emojis) == 2

      emoji_ids = Enum.map(emojis, & &1.discord_id) |> Enum.sort()
      expected_ids = Enum.sort([emoji1_data.id, emoji2_data.id])
      assert emoji_ids == expected_ids

      # Verify emoji attributes
      created_emoji1 = Enum.find(emojis, &(&1.discord_id == emoji1_data.id))
      assert created_emoji1.name == "emoji1"

      created_emoji2 = Enum.find(emojis, &(&1.discord_id == emoji2_data.id))
      assert created_emoji2.name == "emoji2"
    end

    test "updates existing emojis via upsert" do
      guild_id = generate_snowflake()
      old_emoji = emoji(%{name: "old_name"})
      new_emoji = emoji(%{id: old_emoji.id, name: "new_name"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Emoji,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      # Create initial emoji
      {:ok, old_emoji_payload} = Payloads.Emoji.new(old_emoji)

      {:ok, _created} =
        TestApp.Discord.Emoji
        |> Ash.Changeset.for_create(:from_discord, %{
          data: old_emoji_payload,
          identity: %{emoji_id: old_emoji.id, guild_id: guild_id}
        })
        |> Ash.create()

      # Verify initial state
      emojis_before = TestApp.Discord.Emoji.read!()
      assert length(emojis_before) == 1
      assert hd(emojis_before).name == "old_name"

      # Update via handler
      {:ok, new_emoji_payload} = Payloads.Emoji.new(new_emoji)

      guild_emojis_update = %Payloads.GuildEmojisUpdate{
        guild_id: guild_id,
        old_emojis: [old_emoji_payload],
        new_emojis: [new_emoji_payload]
      }

      assert :ok =
               GuildEmojis.update(
                 guild_emojis_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify emoji was updated (not duplicated)
      emojis_after = TestApp.Discord.Emoji.read!()
      assert length(emojis_after) == 1

      updated_emoji = hd(emojis_after)
      assert updated_emoji.discord_id == new_emoji.id
      assert updated_emoji.name == "new_name"
    end

    test "handles empty new_emojis list" do
      guild_id = generate_snowflake()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Emoji,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      guild_emojis_update = %Payloads.GuildEmojisUpdate{
        guild_id: guild_id,
        old_emojis: [],
        new_emojis: []
      }

      # Should not crash with empty list
      assert :ok =
               GuildEmojis.update(
                 guild_emojis_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify no emojis were created
      emojis = TestApp.Discord.Emoji.read!()
      assert length(emojis) == 0
    end

    test "processes multiple emojis in single update" do
      guild_id = generate_snowflake()
      emoji_count = 5

      emoji_data_list =
        Enum.map(1..emoji_count, fn i ->
          emoji(%{name: "emoji_#{i}"})
        end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Emoji,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      emoji_payloads =
        Enum.map(emoji_data_list, fn emoji_data ->
          {:ok, payload} = Payloads.Emoji.new(emoji_data)
          payload
        end)

      guild_emojis_update = %Payloads.GuildEmojisUpdate{
        guild_id: guild_id,
        old_emojis: [],
        new_emojis: emoji_payloads
      }

      assert :ok =
               GuildEmojis.update(
                 guild_emojis_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify all emojis were created
      emojis = TestApp.Discord.Emoji.read!()
      assert length(emojis) == emoji_count

      # Verify all names are present
      emoji_names = Enum.map(emojis, & &1.name) |> Enum.sort()
      expected_names = Enum.map(1..emoji_count, &"emoji_#{&1}") |> Enum.sort()
      assert emoji_names == expected_names
    end
  end
end
