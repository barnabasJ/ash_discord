defmodule AshDiscord.Consumer.Handler.ReactionTest do
  use TestApp.DataCase, async: true

  require Ash.Query

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Reaction
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "add/3" do
    @tag :fixed
    test "creates reaction in database with all relationships" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      user_data = user()
      author_data = user()

      message_data =
        message(%{channel_id: channel_data.id, author: author_data, guild_id: guild_data.id})

      emoji_data = emoji(%{name: "👍", id: nil})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add = %Payloads.MessageReactionAddEvent{
        user_id: user_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: guild_data.id,
        member: nil,
        emoji: emoji_data
      }

      assert :ok =
               Reaction.add(
                 reaction_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [created_reaction] =
        TestApp.Discord.MessageReaction
        |> Ash.Query.load([:user, :message, :channel, :guild])
        |> Ash.read!(authorize?: false)

      assert created_reaction.user.discord_id == user_data.id
      assert created_reaction.message.discord_id == message_data.id
      assert created_reaction.channel.discord_id == channel_data.id
      assert created_reaction.guild.discord_id == guild_data.id
      assert created_reaction.emoji_name == "👍"
      assert created_reaction.emoji_discord_id == nil
    end

    @tag :fixed
    test "creates reaction with custom emoji" do
      channel_data = channel()
      user_data = user()
      author_data = user()
      message_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})
      emoji_data = emoji(%{name: "custom_emoji", animated: true})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add = %Payloads.MessageReactionAddEvent{
        user_id: user_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji_data
      }

      assert :ok =
               Reaction.add(
                 reaction_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [created_reaction] =
        TestApp.Discord.MessageReaction
        |> Ash.Query.load([:user, :message, :channel])
        |> Ash.read!(authorize?: false)

      assert created_reaction.user.discord_id == user_data.id
      assert created_reaction.message.discord_id == message_data.id
      assert created_reaction.channel.discord_id == channel_data.id
      assert created_reaction.emoji_name == "custom_emoji"
      assert created_reaction.emoji_discord_id == emoji_data.id
    end

    @tag :fixed
    test "upserts existing reaction" do
      channel_data = channel()
      user_data = user()
      author_data = user()
      message_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})
      emoji_data = emoji(%{name: "👍", id: nil})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add = %Payloads.MessageReactionAddEvent{
        user_id: user_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji_data
      }

      assert :ok = Reaction.add(reaction_add, %Nostrum.Struct.WSState{}, context)

      assert [_reaction] =
               TestApp.Discord.MessageReaction.read!(
                 query:
                   Ash.Query.filter(
                     TestApp.Discord.MessageReaction,
                     user_discord_id == ^user_data.id and message_discord_id == ^message_data.id and
                       emoji_name == "👍" and
                       is_nil(guild_discord_id) and is_nil(emoji_discord_id)
                   ),
                 authorize?: false
               )

      assert :ok = Reaction.add(reaction_add, %Nostrum.Struct.WSState{}, context)

      assert [_reaction] = TestApp.Discord.MessageReaction.read!(authorize?: false)
    end
  end

  describe "remove/3" do
    @tag :fixed
    test "removes reaction from database" do
      channel_data = channel()
      user_data = user()
      author_data = user()
      message_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})
      emoji_data = emoji(%{name: "👍", id: nil})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add = %Payloads.MessageReactionAddEvent{
        user_id: user_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji_data
      }

      assert :ok = Reaction.add(reaction_add, %Nostrum.Struct.WSState{}, context)

      assert [_reaction] = TestApp.Discord.MessageReaction.read!(authorize?: false)

      reaction_remove = %Payloads.MessageReactionRemoveEvent{
        user_id: user_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        emoji: emoji_data
      }

      assert :ok =
               Reaction.remove(
                 reaction_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )

      assert [] = TestApp.Discord.MessageReaction.read!(authorize?: false)
    end

    @tag :fixed
    test "removes only matching custom emoji reaction" do
      channel_data = channel()
      user_data = user()
      author_data = user()
      message_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})
      emoji1 = emoji(%{name: "emoji1"})
      emoji2 = emoji(%{name: "emoji2"})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add1 = %Payloads.MessageReactionAddEvent{
        user_id: user_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji1
      }

      reaction_add2 = %Payloads.MessageReactionAddEvent{
        user_id: user_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji2
      }

      assert :ok = Reaction.add(reaction_add1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add2, %Nostrum.Struct.WSState{}, context)

      assert [_, _] = TestApp.Discord.MessageReaction.read!(authorize?: false)

      reaction_remove = %Payloads.MessageReactionRemoveEvent{
        user_id: user_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        emoji: emoji1
      }

      assert :ok = Reaction.remove(reaction_remove, %Nostrum.Struct.WSState{}, context)

      assert [remaining] = TestApp.Discord.MessageReaction.read!(authorize?: false)
      assert remaining.emoji_discord_id == emoji2.id
    end

    @tag :fixed
    test "handles missing reaction gracefully" do
      channel_data = channel()
      user_data = user()
      author_data = user()
      message_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})
      emoji_data = emoji(%{name: "👍", id: nil})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_remove = %Payloads.MessageReactionRemoveEvent{
        user_id: user_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        emoji: emoji_data
      }

      assert :ok =
               Reaction.remove(
                 reaction_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end

  describe "remove_all/3" do
    @tag :fixed
    test "removes all reactions from a message" do
      channel_data = channel()
      author_data = user()
      message_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})
      user1_data = user()
      user2_data = user()
      emoji1 = emoji(%{name: "👍", id: nil})
      emoji2 = emoji(%{name: "❤️", id: nil})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user1_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user2_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add1 = %Payloads.MessageReactionAddEvent{
        user_id: user1_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji1
      }

      reaction_add2 = %Payloads.MessageReactionAddEvent{
        user_id: user2_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji1
      }

      reaction_add3 = %Payloads.MessageReactionAddEvent{
        user_id: user1_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji2
      }

      assert :ok = Reaction.add(reaction_add1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add2, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add3, %Nostrum.Struct.WSState{}, context)

      assert [_, _, _] = TestApp.Discord.MessageReaction.read!(authorize?: false)

      reaction_remove_all = %Payloads.MessageReactionRemoveAllEvent{
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil
      }

      assert :ok =
               Reaction.remove_all(
                 reaction_remove_all,
                 %Nostrum.Struct.WSState{},
                 context
               )

      assert [] = TestApp.Discord.MessageReaction.read!(authorize?: false)
    end

    @tag :fixed
    test "only removes reactions from specified message" do
      channel_data = channel()
      author_data = user()
      message1_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})
      message2_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})
      user_data = user()
      emoji_data = emoji(%{name: "👍", id: nil})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message1_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message2_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add1 = %Payloads.MessageReactionAddEvent{
        user_id: user_data.id,
        message_id: message1_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji_data
      }

      reaction_add2 = %Payloads.MessageReactionAddEvent{
        user_id: user_data.id,
        message_id: message2_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji_data
      }

      assert :ok = Reaction.add(reaction_add1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add2, %Nostrum.Struct.WSState{}, context)

      reaction_remove_all = %Payloads.MessageReactionRemoveAllEvent{
        message_id: message1_data.id,
        channel_id: channel_data.id,
        guild_id: nil
      }

      assert :ok =
               Reaction.remove_all(
                 reaction_remove_all,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [remaining] =
        TestApp.Discord.MessageReaction
        |> Ash.Query.load(:message)
        |> Ash.read!(authorize?: false)

      assert remaining.message.discord_id == message2_data.id
    end

    @tag :fixed
    test "handles empty message gracefully" do
      channel_data = channel()
      author_data = user()
      message_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_remove_all = %Payloads.MessageReactionRemoveAllEvent{
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil
      }

      assert :ok =
               Reaction.remove_all(
                 reaction_remove_all,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end

  describe "remove_emoji/3" do
    @tag :fixed
    test "removes all reactions with specific emoji from message" do
      channel_data = channel()
      author_data = user()
      message_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})
      user1_data = user()
      user2_data = user()
      emoji_to_remove = emoji(%{name: "👍", id: nil})
      emoji_to_keep = emoji(%{name: "❤️", id: nil})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user1_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user2_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add1 = %Payloads.MessageReactionAddEvent{
        user_id: user1_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji_to_remove
      }

      reaction_add2 = %Payloads.MessageReactionAddEvent{
        user_id: user2_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji_to_remove
      }

      reaction_add3 = %Payloads.MessageReactionAddEvent{
        user_id: user1_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: emoji_to_keep
      }

      assert :ok = Reaction.add(reaction_add1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add2, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add3, %Nostrum.Struct.WSState{}, context)

      assert [_, _, _] = TestApp.Discord.MessageReaction.read!(authorize?: false)

      reaction_remove_emoji = %Payloads.MessageReactionRemoveEmojiEvent{
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        emoji: emoji_to_remove
      }

      assert :ok =
               Reaction.remove_emoji(
                 reaction_remove_emoji,
                 %Nostrum.Struct.WSState{},
                 context
               )

      assert [remaining] = TestApp.Discord.MessageReaction.read!(authorize?: false)
      assert remaining.emoji_name == "❤️"
    end

    @tag :fixed
    test "removes custom emoji reactions correctly" do
      channel_data = channel()
      author_data = user()
      message_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})
      user1_data = user()
      user2_data = user()
      custom_emoji = emoji(%{name: "custom_emoji"})
      other_emoji = emoji(%{name: "other_emoji"})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user1_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user2_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add1 = %Payloads.MessageReactionAddEvent{
        user_id: user1_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: custom_emoji
      }

      reaction_add2 = %Payloads.MessageReactionAddEvent{
        user_id: user2_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: custom_emoji
      }

      reaction_add3 = %Payloads.MessageReactionAddEvent{
        user_id: user1_data.id,
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        member: nil,
        emoji: other_emoji
      }

      assert :ok = Reaction.add(reaction_add1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add2, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add3, %Nostrum.Struct.WSState{}, context)

      reaction_remove_emoji = %Payloads.MessageReactionRemoveEmojiEvent{
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        emoji: custom_emoji
      }

      assert :ok =
               Reaction.remove_emoji(
                 reaction_remove_emoji,
                 %Nostrum.Struct.WSState{},
                 context
               )

      assert [remaining] = TestApp.Discord.MessageReaction.read!(authorize?: false)
      assert remaining.emoji_discord_id == other_emoji.id
    end

    @tag :fixed
    test "handles missing emoji gracefully" do
      channel_data = channel()
      author_data = user()
      message_data = message(%{channel_id: channel_data.id, author: author_data, guild_id: nil})
      emoji_data = emoji(%{name: "👍", id: nil})

      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_remove_emoji = %Payloads.MessageReactionRemoveEmojiEvent{
        message_id: message_data.id,
        channel_id: channel_data.id,
        guild_id: nil,
        emoji: emoji_data
      }

      assert :ok =
               Reaction.remove_emoji(
                 reaction_remove_emoji,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end
end
