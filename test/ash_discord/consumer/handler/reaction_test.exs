defmodule AshDiscord.Consumer.Handler.ReactionTest do
  use TestApp.DataCase, async: true

  require Ash.Query

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Reaction
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "add/3" do
    test "creates reaction in database" do
      user_id = generate_snowflake()
      message_id = generate_snowflake()
      channel_id = generate_snowflake()
      guild_id = generate_snowflake()
      emoji_data = emoji(%{name: "👍", id: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add = %Payloads.MessageReactionAddEvent{
        user_id: user_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: guild_id,
        member: nil,
        emoji: emoji_data
      }

      assert :ok =
               Reaction.add(
                 reaction_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify reaction was created in database
      reactions = TestApp.Discord.MessageReaction.read!()
      assert length(reactions) == 1

      created_reaction = hd(reactions)
      assert created_reaction.user_discord_id == user_id
      assert created_reaction.message_discord_id == message_id
      assert created_reaction.channel_discord_id == channel_id
      assert created_reaction.guild_discord_id == guild_id
      assert created_reaction.emoji_name == "👍"
      assert created_reaction.emoji_discord_id == nil
    end

    test "creates reaction with custom emoji" do
      user_id = generate_snowflake()
      message_id = generate_snowflake()
      channel_id = generate_snowflake()
      emoji_data = emoji(%{name: "custom_emoji", animated: true})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add = %Payloads.MessageReactionAddEvent{
        user_id: user_id,
        message_id: message_id,
        channel_id: channel_id,
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

      # Verify reaction was created with custom emoji
      reactions = TestApp.Discord.MessageReaction.read!()
      assert length(reactions) == 1

      created_reaction = hd(reactions)
      assert created_reaction.emoji_name == "custom_emoji"
      assert created_reaction.emoji_discord_id == emoji_data.id
    end

    test "upserts existing reaction" do
      user_id = generate_snowflake()
      message_id = generate_snowflake()
      channel_id = generate_snowflake()
      emoji_data = emoji(%{name: "👍", id: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_add = %Payloads.MessageReactionAddEvent{
        user_id: user_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji_data
      }

      # Add reaction twice
      assert :ok = Reaction.add(reaction_add, %Nostrum.Struct.WSState{}, context)

      assert [_reactions] =
               TestApp.Discord.MessageReaction.read!(
                 query:
                   Ash.Query.filter(
                     TestApp.Discord.MessageReaction,
                     user_discord_id == ^user_id and message_discord_id == ^message_id and
                       emoji_name == "👍" and
                       is_nil(guild_discord_id) and is_nil(emoji_discord_id)
                   )
               )

      assert :ok = Reaction.add(reaction_add, %Nostrum.Struct.WSState{}, context)

      # Verify only one reaction exists (upserted)
      assert [_reactions] = TestApp.Discord.MessageReaction.read!()
    end
  end

  describe "remove/3" do
    test "removes reaction from database" do
      user_id = generate_snowflake()
      message_id = generate_snowflake()
      channel_id = generate_snowflake()
      emoji_data = emoji(%{name: "👍", id: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      # First create the reaction
      reaction_add = %Payloads.MessageReactionAddEvent{
        user_id: user_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji_data
      }

      assert :ok = Reaction.add(reaction_add, %Nostrum.Struct.WSState{}, context)

      # Verify reaction exists
      reactions_before = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_before) == 1

      # Now remove it
      reaction_remove = %Payloads.MessageReactionRemoveEvent{
        user_id: user_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        emoji: emoji_data
      }

      assert :ok =
               Reaction.remove(
                 reaction_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify reaction was deleted
      reactions_after = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_after) == 0
    end

    test "removes only matching custom emoji reaction" do
      user_id = generate_snowflake()
      message_id = generate_snowflake()
      channel_id = generate_snowflake()
      emoji1 = emoji(%{name: "emoji1"})
      emoji2 = emoji(%{name: "emoji2"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      # Create two different emoji reactions from same user on same message
      reaction_add1 = %Payloads.MessageReactionAddEvent{
        user_id: user_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji1
      }

      reaction_add2 = %Payloads.MessageReactionAddEvent{
        user_id: user_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji2
      }

      assert :ok = Reaction.add(reaction_add1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add2, %Nostrum.Struct.WSState{}, context)

      # Verify both reactions exist
      reactions_before = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_before) == 2

      # Remove only emoji1
      reaction_remove = %Payloads.MessageReactionRemoveEvent{
        user_id: user_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        emoji: emoji1
      }

      assert :ok = Reaction.remove(reaction_remove, %Nostrum.Struct.WSState{}, context)

      # Verify only emoji2 reaction remains
      reactions_after = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_after) == 1
      assert hd(reactions_after).emoji_discord_id == emoji2.id
    end

    test "handles missing reaction gracefully" do
      user_id = generate_snowflake()
      message_id = generate_snowflake()
      channel_id = generate_snowflake()
      emoji_data = emoji(%{name: "👍", id: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_remove = %Payloads.MessageReactionRemoveEvent{
        user_id: user_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        emoji: emoji_data
      }

      # Should not crash when reaction doesn't exist
      assert :ok =
               Reaction.remove(
                 reaction_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end

  describe "remove_all/3" do
    test "removes all reactions from a message" do
      message_id = generate_snowflake()
      channel_id = generate_snowflake()
      user1_id = generate_snowflake()
      user2_id = generate_snowflake()
      emoji1 = emoji(%{name: "👍", id: nil})
      emoji2 = emoji(%{name: "❤️", id: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      # Create multiple reactions
      reaction_add1 = %Payloads.MessageReactionAddEvent{
        user_id: user1_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji1
      }

      reaction_add2 = %Payloads.MessageReactionAddEvent{
        user_id: user2_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji1
      }

      reaction_add3 = %Payloads.MessageReactionAddEvent{
        user_id: user1_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji2
      }

      assert :ok = Reaction.add(reaction_add1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add2, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add3, %Nostrum.Struct.WSState{}, context)

      # Verify all reactions exist
      reactions_before = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_before) == 3

      # Remove all reactions
      reaction_remove_all = %Payloads.MessageReactionRemoveAllEvent{
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil
      }

      assert :ok =
               Reaction.remove_all(
                 reaction_remove_all,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify all reactions were deleted
      reactions_after = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_after) == 0
    end

    test "only removes reactions from specified message" do
      message1_id = generate_snowflake()
      message2_id = generate_snowflake()
      channel_id = generate_snowflake()
      user_id = generate_snowflake()
      emoji_data = emoji(%{name: "👍", id: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      # Create reactions on two different messages
      reaction_add1 = %Payloads.MessageReactionAddEvent{
        user_id: user_id,
        message_id: message1_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji_data
      }

      reaction_add2 = %Payloads.MessageReactionAddEvent{
        user_id: user_id,
        message_id: message2_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji_data
      }

      assert :ok = Reaction.add(reaction_add1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add2, %Nostrum.Struct.WSState{}, context)

      # Remove all reactions from message1 only
      reaction_remove_all = %Payloads.MessageReactionRemoveAllEvent{
        message_id: message1_id,
        channel_id: channel_id,
        guild_id: nil
      }

      assert :ok =
               Reaction.remove_all(
                 reaction_remove_all,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify only message2 reaction remains
      reactions_after = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_after) == 1
      assert hd(reactions_after).message_discord_id == message2_id
    end

    test "handles empty message gracefully" do
      message_id = generate_snowflake()
      channel_id = generate_snowflake()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_remove_all = %Payloads.MessageReactionRemoveAllEvent{
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil
      }

      # Should not crash when no reactions exist
      assert :ok =
               Reaction.remove_all(
                 reaction_remove_all,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end

  describe "remove_emoji/3" do
    test "removes all reactions with specific emoji from message" do
      message_id = generate_snowflake()
      channel_id = generate_snowflake()
      user1_id = generate_snowflake()
      user2_id = generate_snowflake()
      emoji_to_remove = emoji(%{name: "👍", id: nil})
      emoji_to_keep = emoji(%{name: "❤️", id: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      # Create reactions with two different emojis
      reaction_add1 = %Payloads.MessageReactionAddEvent{
        user_id: user1_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji_to_remove
      }

      reaction_add2 = %Payloads.MessageReactionAddEvent{
        user_id: user2_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji_to_remove
      }

      reaction_add3 = %Payloads.MessageReactionAddEvent{
        user_id: user1_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: emoji_to_keep
      }

      assert :ok = Reaction.add(reaction_add1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add2, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add3, %Nostrum.Struct.WSState{}, context)

      # Verify all reactions exist
      reactions_before = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_before) == 3

      # Remove all 👍 emoji reactions
      reaction_remove_emoji = %Payloads.MessageReactionRemoveEmojiEvent{
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        emoji: emoji_to_remove
      }

      assert :ok =
               Reaction.remove_emoji(
                 reaction_remove_emoji,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify only ❤️ reaction remains
      reactions_after = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_after) == 1
      assert hd(reactions_after).emoji_name == "❤️"
    end

    test "removes custom emoji reactions correctly" do
      message_id = generate_snowflake()
      channel_id = generate_snowflake()
      user1_id = generate_snowflake()
      user2_id = generate_snowflake()
      custom_emoji = emoji(%{name: "custom_emoji"})
      other_emoji = emoji(%{name: "other_emoji"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      # Create reactions with custom emojis
      reaction_add1 = %Payloads.MessageReactionAddEvent{
        user_id: user1_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: custom_emoji
      }

      reaction_add2 = %Payloads.MessageReactionAddEvent{
        user_id: user2_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: custom_emoji
      }

      reaction_add3 = %Payloads.MessageReactionAddEvent{
        user_id: user1_id,
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        member: nil,
        emoji: other_emoji
      }

      assert :ok = Reaction.add(reaction_add1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add2, %Nostrum.Struct.WSState{}, context)
      assert :ok = Reaction.add(reaction_add3, %Nostrum.Struct.WSState{}, context)

      # Remove all custom_emoji reactions
      reaction_remove_emoji = %Payloads.MessageReactionRemoveEmojiEvent{
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        emoji: custom_emoji
      }

      assert :ok =
               Reaction.remove_emoji(
                 reaction_remove_emoji,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify only other_emoji reaction remains
      reactions_after = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_after) == 1
      assert hd(reactions_after).emoji_discord_id == other_emoji.id
    end

    test "handles missing emoji gracefully" do
      message_id = generate_snowflake()
      channel_id = generate_snowflake()
      emoji_data = emoji(%{name: "👍", id: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil
      }

      reaction_remove_emoji = %Payloads.MessageReactionRemoveEmojiEvent{
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        emoji: emoji_data
      }

      # Should not crash when emoji doesn't exist
      assert :ok =
               Reaction.remove_emoji(
                 reaction_remove_emoji,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end
end
