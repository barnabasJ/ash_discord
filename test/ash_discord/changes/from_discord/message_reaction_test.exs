defmodule AshDiscord.Changes.FromDiscord.MessageReactionTest do
  @moduledoc """
  Comprehensive tests for MessageReaction entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates message reaction from discord struct with unicode emoji" do
      user_id = 111_222_333
      channel_id = 777_888_999
      guild_id = 333_444_555

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel", guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: "👍", animated: false},
          user_id: user_id,
          message_id: 444_555_666,
          channel_id: channel_id,
          guild_id: guild_id
        })

      created_reaction =
        TestApp.Discord.message_reaction_from_discord!(
          %{data: reaction_event},
          load: [:user, :channel, :guild]
        )

      assert created_reaction.emoji_discord_id == nil
      assert created_reaction.emoji_name == "👍"
      assert created_reaction.count == 1
      assert created_reaction.me == false
      assert created_reaction.user.discord_id == user_id
      assert created_reaction.channel.discord_id == channel_id
      assert created_reaction.guild.discord_id == guild_id
    end

    @tag :fixed
    test "creates message reaction with custom emoji" do
      user_id = 111_222_333
      channel_id = 777_888_999
      guild_id = 333_444_555

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel", guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: 987_654_321, name: "custom_emoji", animated: false},
          user_id: user_id,
          message_id: 444_555_666,
          channel_id: channel_id,
          guild_id: guild_id
        })

      created_reaction =
        TestApp.Discord.message_reaction_from_discord!(
          %{data: reaction_event},
          load: [:user, :channel, :guild]
        )

      assert created_reaction.emoji_discord_id == 987_654_321
      assert created_reaction.emoji_name == "custom_emoji"
      assert created_reaction.count == 1
      assert created_reaction.me == false
      assert created_reaction.user.discord_id == user_id
      assert created_reaction.channel.discord_id == channel_id
      assert created_reaction.guild.discord_id == guild_id
    end

    @tag :fixed
    test "creates message reaction with animated custom emoji" do
      user_id = 777_888_999
      channel_id = 444_555_666
      guild_id = 999_111_222

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel", guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: 555_666_777, name: "animated_party", animated: true},
          user_id: user_id,
          message_id: 111_222_333,
          channel_id: channel_id,
          guild_id: guild_id
        })

      created_reaction =
        TestApp.Discord.message_reaction_from_discord!(
          %{data: reaction_event},
          load: [:user, :channel, :guild]
        )

      assert created_reaction.emoji_discord_id == 555_666_777
      assert created_reaction.emoji_name == "animated_party"
      assert created_reaction.count == 1
      assert created_reaction.user.discord_id == user_id
      assert created_reaction.channel.discord_id == channel_id
      assert created_reaction.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles single count reaction" do
      user_id = 333_444_555
      channel_id = 999_111_222
      guild_id = 222_333_444

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel", guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: "❤️", animated: false},
          user_id: user_id,
          message_id: 666_777_888,
          channel_id: channel_id,
          guild_id: guild_id
        })

      created_reaction =
        TestApp.Discord.message_reaction_from_discord!(
          %{data: reaction_event},
          load: [:user, :channel, :guild]
        )

      assert created_reaction.emoji_name == "❤️"
      assert created_reaction.count == 1
      assert created_reaction.me == false
      assert created_reaction.user.discord_id == user_id
      assert created_reaction.channel.discord_id == channel_id
      assert created_reaction.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles high count reaction" do
      user_id = 888_999_111
      channel_id = 555_666_777
      guild_id = 111_222_333

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel", guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: "🔥", animated: false},
          user_id: user_id,
          message_id: 222_333_444,
          channel_id: channel_id,
          guild_id: guild_id
        })

      created_reaction =
        TestApp.Discord.message_reaction_from_discord!(
          %{data: reaction_event},
          load: [:user, :channel, :guild]
        )

      assert created_reaction.emoji_name == "🔥"
      assert created_reaction.count == 1
      assert created_reaction.user.discord_id == user_id
      assert created_reaction.channel.discord_id == channel_id
      assert created_reaction.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles DM reaction without guild_id" do
      user_id = 444_555_666
      channel_id = 111_222_333

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel", guild_id: nil})}
      end)

      reaction_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: "😊", animated: false},
          user_id: user_id,
          message_id: 777_888_999,
          channel_id: channel_id,
          guild_id: nil
        })

      created_reaction =
        TestApp.Discord.message_reaction_from_discord!(
          %{data: reaction_event},
          load: [:user, :channel]
        )

      assert created_reaction.emoji_name == "😊"
      assert created_reaction.guild_discord_id == nil
      assert created_reaction.user.discord_id == user_id
      assert created_reaction.channel.discord_id == channel_id
    end
  end

  describe "API fallback pattern" do
    @tag :fixed
    test "fetches message reaction from API when data not provided" do
      channel_id = 555_666_777
      message_id = 999_888_777
      user_id = 123_456_789
      guild_id = 111_222_333
      emoji_name = "👍"

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel", guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      expect(Nostrum.Api.Message, :get, fn ^channel_id, ^message_id ->
        {:ok,
         message(%{
           id: message_id,
           channel_id: channel_id,
           guild_id: guild_id,
           content: "Test message",
           reactions: [
             %{
               count: 5,
               me: false,
               emoji: %{id: nil, name: emoji_name, animated: false}
             }
           ]
         })}
      end)

      result =
        TestApp.Discord.message_reaction_from_discord(%{
          identity: %{
            channel_id: channel_id,
            message_id: message_id,
            emoji_name: emoji_name,
            user_id: user_id
          }
        })

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_name == emoji_name
      assert created_reaction.emoji_discord_id == nil
      assert created_reaction.user_discord_id == user_id
      assert created_reaction.message_discord_id == message_id
      assert created_reaction.channel_discord_id == channel_id
    end

    @tag :fixed
    test "fetches custom emoji reaction from API" do
      channel_id = 555_666_777
      message_id = 999_888_777
      user_id = 123_456_789
      guild_id = 222_333_444
      emoji_id = 987_654_321
      emoji_name = "custom_emoji"

      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel", guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      expect(Nostrum.Api.Message, :get, fn ^channel_id, ^message_id ->
        {:ok,
         message(%{
           id: message_id,
           channel_id: channel_id,
           guild_id: guild_id,
           content: "Test message",
           reactions: [
             %{
               count: 3,
               me: true,
               emoji: %{id: emoji_id, name: emoji_name, animated: true}
             }
           ]
         })}
      end)

      result =
        TestApp.Discord.message_reaction_from_discord(%{
          identity: %{
            channel_id: channel_id,
            message_id: message_id,
            emoji_id: emoji_id,
            emoji_name: emoji_name,
            user_id: user_id
          }
        })

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_name == emoji_name
      assert created_reaction.emoji_discord_id == emoji_id
      assert created_reaction.user_discord_id == user_id
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing message reaction instead of creating duplicate" do
      user_id = 555_666_777
      message_id = 111_222_333
      channel_id = 444_555_666
      guild_id = 777_888_999
      emoji_name = "👍"
      emoji_id = 123_456_789

      # First set of expectations for initial creation
      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel", guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      initial_event =
        message_reaction_add_event(%{
          emoji: %{id: emoji_id, name: emoji_name, animated: false},
          user_id: user_id,
          message_id: message_id,
          channel_id: channel_id,
          guild_id: guild_id
        })

      original_reaction =
        TestApp.Discord.message_reaction_from_discord!(%{data: initial_event})

      updated_event =
        message_reaction_add_event(%{
          emoji: %{id: emoji_id, name: emoji_name, animated: false},
          user_id: user_id,
          message_id: message_id,
          channel_id: channel_id,
          guild_id: guild_id
        })

      updated_reaction =
        TestApp.Discord.message_reaction_from_discord!(%{data: updated_event})

      assert updated_reaction.id == original_reaction.id
      assert updated_reaction.user_discord_id == original_reaction.user_discord_id
      assert updated_reaction.message_discord_id == original_reaction.message_discord_id
      assert updated_reaction.emoji_name == original_reaction.emoji_name
    end

    @tag :fixed
    test "updates existing standard emoji reaction instead of creating duplicate" do
      user_id = 777_888_999
      message_id = 222_333_444
      channel_id = 555_666_777
      guild_id = 888_999_000
      emoji_name = "❤️"

      # First set of expectations for initial creation
      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel", guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      initial_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: emoji_name, animated: false},
          user_id: user_id,
          message_id: message_id,
          channel_id: channel_id,
          guild_id: guild_id
        })

      original_reaction =
        TestApp.Discord.message_reaction_from_discord!(%{data: initial_event})

      updated_event =
        message_reaction_add_event(%{
          emoji: %{id: nil, name: emoji_name, animated: false},
          user_id: user_id,
          message_id: message_id,
          channel_id: channel_id,
          guild_id: guild_id
        })

      updated_reaction =
        TestApp.Discord.message_reaction_from_discord!(%{data: updated_event})

      assert updated_reaction.id == original_reaction.id
      assert updated_reaction.user_discord_id == original_reaction.user_discord_id
      assert updated_reaction.message_discord_id == original_reaction.message_discord_id
      assert updated_reaction.emoji_name == original_reaction.emoji_name
      assert updated_reaction.emoji_discord_id == nil
    end

    @tag :fixed
    test "upsert works with custom emoji reactions" do
      user_id = 333_444_555
      message_id = 777_888_999
      channel_id = 999_111_222
      guild_id = 222_333_444
      emoji_id = 123_456_789

      # First set of expectations for initial creation
      expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "test-channel", guild_id: guild_id})}
      end)

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      initial_event =
        message_reaction_add_event(%{
          emoji: %{id: emoji_id, name: "custom_emoji", animated: false},
          user_id: user_id,
          message_id: message_id,
          channel_id: channel_id,
          guild_id: guild_id
        })

      original_reaction =
        TestApp.Discord.message_reaction_from_discord!(%{data: initial_event})

      updated_event =
        message_reaction_add_event(%{
          emoji: %{id: emoji_id, name: "custom_emoji", animated: true},
          user_id: user_id,
          message_id: message_id,
          channel_id: channel_id,
          guild_id: guild_id
        })

      updated_reaction =
        TestApp.Discord.message_reaction_from_discord!(%{data: updated_event})

      assert updated_reaction.id == original_reaction.id
      assert updated_reaction.user_discord_id == user_id
      assert updated_reaction.message_discord_id == message_id
      assert updated_reaction.emoji_discord_id == emoji_id
    end
  end
end
