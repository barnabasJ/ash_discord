defmodule AshDiscord.Consumer.Handler.GuildEmojisTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.GuildEmojis
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/3" do
    @tag :fixed
    test "creates emojis from new_emojis list in database" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      emoji1_data = emoji(%{name: "emoji1"})
      emoji2_data = emoji(%{name: "emoji2"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Emoji,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      emoji1_payload = Payloads.Emoji.new!(emoji1_data)
      emoji2_payload = Payloads.Emoji.new!(emoji2_data)

      guild_emojis_update = %Payloads.GuildEmojisUpdate{
        guild_id: guild.id,
        old_emojis: [],
        new_emojis: [emoji1_payload, emoji2_payload]
      }

      assert :ok =
               GuildEmojis.update(
                 guild_emojis_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      emojis = TestApp.Discord.Emoji.read!(authorize?: false)
      assert length(emojis) == 2

      emoji_ids = Enum.map(emojis, & &1.discord_id) |> Enum.sort()
      expected_ids = Enum.sort([emoji1_data.id, emoji2_data.id])
      assert emoji_ids == expected_ids

      created_emoji1 = Enum.find(emojis, &(&1.discord_id == emoji1_data.id))
      assert created_emoji1.name == "emoji1"
      assert created_emoji1.guild_discord_id == guild.id

      created_emoji2 = Enum.find(emojis, &(&1.discord_id == emoji2_data.id))
      assert created_emoji2.name == "emoji2"
      assert created_emoji2.guild_discord_id == guild.id
    end

    @tag :fixed
    test "updates existing emojis via upsert" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      old_emoji = emoji(%{name: "old_name"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Emoji,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      old_emoji_payload = Payloads.Emoji.new!(old_emoji)

      TestApp.Discord.emoji_from_discord!(
        %{
          data: old_emoji_payload,
          identity: %{emoji_id: old_emoji.id, guild_id: guild.id}
        },
        authorize?: false
      )

      [emoji_before] = TestApp.Discord.Emoji.read!(authorize?: false)
      assert emoji_before.name == "old_name"

      new_emoji = emoji(%{id: old_emoji.id, name: "new_name"})
      new_emoji_payload = Payloads.Emoji.new!(new_emoji)

      guild_emojis_update = %Payloads.GuildEmojisUpdate{
        guild_id: guild.id,
        old_emojis: [old_emoji_payload],
        new_emojis: [new_emoji_payload]
      }

      assert :ok =
               GuildEmojis.update(
                 guild_emojis_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [updated_emoji] = TestApp.Discord.Emoji.read!(authorize?: false)
      assert updated_emoji.discord_id == new_emoji.id
      assert updated_emoji.name == "new_name"
      assert updated_emoji.guild_discord_id == guild.id
    end

    @tag :fixed
    test "handles empty new_emojis list" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Emoji,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      guild_emojis_update = %Payloads.GuildEmojisUpdate{
        guild_id: guild.id,
        old_emojis: [],
        new_emojis: []
      }

      assert :ok =
               GuildEmojis.update(
                 guild_emojis_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      emojis = TestApp.Discord.Emoji.read!(authorize?: false)
      assert length(emojis) == 0
    end

    @tag :fixed
    test "processes multiple emojis in single update" do
      guild = guild()
      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

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
          Payloads.Emoji.new!(emoji_data)
        end)

      guild_emojis_update = %Payloads.GuildEmojisUpdate{
        guild_id: guild.id,
        old_emojis: [],
        new_emojis: emoji_payloads
      }

      assert :ok =
               GuildEmojis.update(
                 guild_emojis_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      emojis = TestApp.Discord.Emoji.read!(authorize?: false)
      assert length(emojis) == emoji_count

      emoji_names = Enum.map(emojis, & &1.name) |> Enum.sort()
      expected_names = Enum.map(1..emoji_count, &"emoji_#{&1}") |> Enum.sort()
      assert emoji_names == expected_names

      Enum.each(emojis, fn emoji ->
        assert emoji.guild_discord_id == guild.id
      end)
    end

    # TODO: add tests for deleting emojis if they are only in the old list
  end
end
