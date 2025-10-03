defmodule AshDiscord.Consumer.Handler.Message.ReactionTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Consumer.Handler.Message.Reaction
  alias TestApp.TestConsumer

  describe "add/4" do
    test "creates message reaction in database" do
      reaction_event = message_reaction_add_event()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
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
          discord_struct: reaction_event,
          user_id: reaction_event.user_id,
          message_id: reaction_event.message_id,
          channel_id: reaction_event.channel_id,
          guild_id: reaction_event.guild_id
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
        resource: nil,
        guild: nil,
        user: nil
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

      # Create multiple reactions for the same message
      reaction_event1 =
        message_reaction_add_event(%{
          message_id: message_id,
          emoji: %{id: nil, name: "👍", animated: false}
        })

      reaction_event2 =
        message_reaction_add_event(%{
          message_id: message_id,
          emoji: %{id: nil, name: "❤️", animated: false}
        })

      {:ok, _} =
        TestApp.Discord.MessageReaction
        |> Ash.Changeset.for_create(:from_discord, %{
          discord_struct: reaction_event1,
          user_id: reaction_event1.user_id,
          message_id: reaction_event1.message_id,
          channel_id: reaction_event1.channel_id,
          guild_id: reaction_event1.guild_id
        })
        |> Ash.create()

      {:ok, _} =
        TestApp.Discord.MessageReaction
        |> Ash.Changeset.for_create(:from_discord, %{
          discord_struct: reaction_event2,
          user_id: reaction_event2.user_id,
          message_id: reaction_event2.message_id,
          channel_id: reaction_event2.channel_id,
          guild_id: reaction_event2.guild_id
        })
        |> Ash.create()

      # Verify reactions exist
      reactions_before = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_before) == 2

      remove_all_event = message_reaction_remove_all_event(%{message_id: message_id})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Reaction.all(TestConsumer, remove_all_event, %Nostrum.Struct.WSState{}, context)

      # Verify all reactions were deleted from database
      reactions_after = TestApp.Discord.MessageReaction.read!()
      assert length(reactions_after) == 0
    end

    test "handles empty reactions list gracefully" do
      remove_all_event = message_reaction_remove_all_event()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      # Should not crash when no reactions exist
      assert :ok =
               Reaction.all(TestConsumer, remove_all_event, %Nostrum.Struct.WSState{}, context)
    end
  end

  describe "emoji/4" do
    test "returns :ok without side effects" do
      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      # This is a no-op handler
      assert :ok = Reaction.emoji(TestConsumer, %{}, %Nostrum.Struct.WSState{}, context)
    end
  end
end
