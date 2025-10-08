defmodule AshDiscord.Consumer.Handler.Message.ReactionTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Message.Reaction
  alias TestApp.TestConsumer

  describe "add/4" do
    test "creates message reaction in database" do
      reaction_event = message_reaction_add_event()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok =
               Reaction.add(TestConsumer, reaction_event, %Nostrum.Struct.WSState{}, context)

      # Verify reaction was created in database
      reactions = TestApp.Discord.MessageReaction.read!()
      assert length(reactions) == 1

      created_reaction = hd(reactions)
      assert created_reaction.user_id == reaction_event.user_id
      assert created_reaction.message_id == reaction_event.message_id
      assert created_reaction.emoji_name == reaction_event.emoji.name
    end
  end

  describe "remove/4" do
    test "removes message reaction from database" do
      reaction_event = message_reaction_add_event()

      # First create the reaction
      {:ok, _created} =
        TestApp.Discord.MessageReaction
        |> Ash.Changeset.for_create(:from_discord, %{
          data: reaction_event
        })
        |> Ash.create()

      # Verify reaction exists
      reactions_before = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_before) == 1

      # Create remove event with matching data
      remove_event =
        message_reaction_remove_event(%{
          user_id: reaction_event.user_id,
          message_id: reaction_event.message_id,
          emoji: reaction_event.emoji
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok =
               Reaction.remove(TestConsumer, remove_event, %Nostrum.Struct.WSState{}, context)

      # Verify reaction was deleted from database
      reactions_after = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_after) == 0
    end
  end

  describe "all/4" do
    test "removes all reactions for a message from database" do
      message_id = generate_snowflake()
      channel_id = generate_snowflake()

      # Create multiple reactions for the same message
      reaction_event1 =
        message_reaction_add_event(%{
          message_id: message_id,
          channel_id: channel_id,
          emoji: %{id: nil, name: "👍", animated: false}
        })

      reaction_event2 =
        message_reaction_add_event(%{
          message_id: message_id,
          channel_id: channel_id,
          emoji: %{id: nil, name: "❤️", animated: false}
        })

      {:ok, _} =
        TestApp.Discord.MessageReaction
        |> Ash.Changeset.for_create(:from_discord, %{
          data: reaction_event1
        })
        |> Ash.create()

      {:ok, _} =
        TestApp.Discord.MessageReaction
        |> Ash.Changeset.for_create(:from_discord, %{
          data: reaction_event2
        })
        |> Ash.create()

      # Verify reactions exist
      reactions_before = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_before) == 2

      remove_all_event =
        message_reaction_remove_all_event(%{message_id: message_id, channel_id: channel_id})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok =
               Reaction.remove_all(
                 TestConsumer,
                 remove_all_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify all reactions were deleted from database
      reactions_after = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_after) == 0
    end

    test "handles empty reactions list gracefully" do
      remove_all_event = message_reaction_remove_all_event()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      # Should not crash when no reactions exist
      assert :ok =
               Reaction.remove_all(
                 TestConsumer,
                 remove_all_event,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end

  describe "remove_emoji/4" do
    test "removes all reactions with specific emoji from message" do
      message_id = generate_snowflake()
      channel_id = generate_snowflake()
      emoji_to_remove = %{id: nil, name: "👍", animated: false}

      # Create multiple reactions with the emoji to be removed
      reaction_event1 =
        message_reaction_add_event(%{
          message_id: message_id,
          channel_id: channel_id,
          emoji: emoji_to_remove
        })

      reaction_event2 =
        message_reaction_add_event(%{
          message_id: message_id,
          channel_id: channel_id,
          emoji: emoji_to_remove
        })

      {:ok, _} =
        TestApp.Discord.MessageReaction
        |> Ash.Changeset.for_create(:from_discord, %{data: reaction_event1})
        |> Ash.create()

      {:ok, _} =
        TestApp.Discord.MessageReaction
        |> Ash.Changeset.for_create(:from_discord, %{data: reaction_event2})
        |> Ash.create()

      # Verify reactions exist
      reactions_before = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_before) == 2

      remove_emoji_event = %AshDiscord.Consumer.Payloads.MessageReactionRemoveEmojiEvent{
        message_id: message_id,
        channel_id: channel_id,
        guild_id: nil,
        emoji: struct(Nostrum.Struct.Emoji, emoji_to_remove)
      }

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessageReaction,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      assert :ok =
               Reaction.remove_emoji(
                 TestConsumer,
                 remove_emoji_event,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify all reactions with that emoji were deleted
      reactions_after = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_after) == 0
    end
  end
end
