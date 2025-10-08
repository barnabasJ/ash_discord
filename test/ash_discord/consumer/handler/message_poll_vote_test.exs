defmodule AshDiscord.Consumer.Handler.MessagePollVoteTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.MessagePollVote
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "add/3" do
    test "creates poll vote from Discord event" do
      poll_vote_event = poll_vote_change_event(%{type: :add})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      {:ok, poll_vote_payload} = Payloads.PollVoteChangeEvent.new(poll_vote_event)

      assert :ok = MessagePollVote.add(poll_vote_payload, %Nostrum.Struct.WSState{}, context)

      poll_votes = TestApp.Discord.MessagePollVote.read!()
      assert length(poll_votes) == 1

      created_vote = hd(poll_votes)
      assert created_vote.user_id == poll_vote_event.user_id
      assert created_vote.message_id == poll_vote_event.message_id
      assert created_vote.answer_id == poll_vote_event.answer_id
    end

    test "handles upsert correctly for duplicate votes" do
      poll_vote_event = poll_vote_change_event(%{type: :add, answer_id: 1})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      {:ok, poll_vote_payload} = Payloads.PollVoteChangeEvent.new(poll_vote_event)

      # Add the same vote twice
      assert :ok = MessagePollVote.add(poll_vote_payload, %Nostrum.Struct.WSState{}, context)
      assert :ok = MessagePollVote.add(poll_vote_payload, %Nostrum.Struct.WSState{}, context)

      poll_votes = TestApp.Discord.MessagePollVote.read!()
      # Should only have one vote due to upsert
      assert length(poll_votes) == 1
    end

    test "handles multiple votes for different answers" do
      user_id = generate_snowflake()
      message_id = generate_snowflake()

      vote1 = poll_vote_change_event(%{user_id: user_id, message_id: message_id, answer_id: 1})
      vote2 = poll_vote_change_event(%{user_id: user_id, message_id: message_id, answer_id: 2})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      {:ok, payload1} = Payloads.PollVoteChangeEvent.new(vote1)
      {:ok, payload2} = Payloads.PollVoteChangeEvent.new(vote2)

      assert :ok = MessagePollVote.add(payload1, %Nostrum.Struct.WSState{}, context)
      assert :ok = MessagePollVote.add(payload2, %Nostrum.Struct.WSState{}, context)

      poll_votes = TestApp.Discord.MessagePollVote.read!()
      assert length(poll_votes) == 2
    end
  end

  describe "remove/3" do
    test "removes poll vote by user_id, message_id, and answer_id" do
      poll_vote_event = poll_vote_change_event(%{type: :add})

      # Create a vote first
      {:ok, _created} =
        TestApp.Discord.MessagePollVote
        |> Ash.Changeset.for_create(:from_discord, %{
          data: poll_vote_event
        })
        |> Ash.create()

      votes_before = TestApp.Discord.MessagePollVote.read!()
      assert length(votes_before) == 1

      # Create remove event with same identifiers
      remove_event = %{poll_vote_event | type: :remove}

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      {:ok, remove_payload} = Payloads.PollVoteChangeEvent.new(remove_event)

      assert :ok = MessagePollVote.remove(remove_payload, %Nostrum.Struct.WSState{}, context)

      votes_after = TestApp.Discord.MessagePollVote.read!()
      assert length(votes_after) == 0
    end

    test "removes only matching vote when multiple exist" do
      user_id = generate_snowflake()
      message_id = generate_snowflake()

      vote1 = poll_vote_change_event(%{user_id: user_id, message_id: message_id, answer_id: 1})
      vote2 = poll_vote_change_event(%{user_id: user_id, message_id: message_id, answer_id: 2})

      # Create two votes
      {:ok, _} =
        TestApp.Discord.MessagePollVote
        |> Ash.Changeset.for_create(:from_discord, %{data: vote1})
        |> Ash.create()

      {:ok, _} =
        TestApp.Discord.MessagePollVote
        |> Ash.Changeset.for_create(:from_discord, %{data: vote2})
        |> Ash.create()

      votes_before = TestApp.Discord.MessagePollVote.read!()
      assert length(votes_before) == 2

      # Remove only vote1
      remove_event = %{vote1 | type: :remove}

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      {:ok, remove_payload} = Payloads.PollVoteChangeEvent.new(remove_event)

      assert :ok = MessagePollVote.remove(remove_payload, %Nostrum.Struct.WSState{}, context)

      votes_after = TestApp.Discord.MessagePollVote.read!()
      assert length(votes_after) == 1

      remaining_vote = hd(votes_after)
      assert remaining_vote.answer_id == 2
    end

    test "handles removing non-existent vote gracefully" do
      poll_vote_event = poll_vote_change_event(%{type: :remove})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      {:ok, poll_vote_payload} = Payloads.PollVoteChangeEvent.new(poll_vote_event)

      # Should not error when trying to remove non-existent vote
      assert :ok = MessagePollVote.remove(poll_vote_payload, %Nostrum.Struct.WSState{}, context)
    end
  end
end
