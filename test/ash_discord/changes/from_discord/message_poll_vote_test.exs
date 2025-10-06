defmodule AshDiscord.Changes.FromDiscord.MessagePollVoteTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators.Discord

  alias TestApp.Discord.MessagePollVote

  describe "from_discord change" do
    test "transforms poll vote data correctly" do
      poll_vote_event =
        poll_vote_change_event(%{
          user_id: generate_snowflake(),
          message_id: generate_snowflake(),
          channel_id: generate_snowflake(),
          guild_id: generate_snowflake(),
          answer_id: 2,
          type: :add
        })

      {:ok, created} =
        MessagePollVote
        |> Ash.Changeset.for_create(:from_discord, %{
          data: poll_vote_event
        })
        |> Ash.create()

      assert created.user_id == poll_vote_event.user_id
      assert created.message_id == poll_vote_event.message_id
      assert created.channel_id == poll_vote_event.channel_id
      assert created.guild_id == poll_vote_event.guild_id
      assert created.answer_id == poll_vote_event.answer_id
    end

    test "upserts poll vote when same user votes for same answer" do
      poll_vote_event =
        poll_vote_change_event(%{
          user_id: generate_snowflake(),
          message_id: generate_snowflake(),
          channel_id: generate_snowflake(),
          guild_id: generate_snowflake(),
          answer_id: 1,
          type: :add
        })

      {:ok, first} =
        MessagePollVote
        |> Ash.Changeset.for_create(:from_discord, %{
          data: poll_vote_event
        })
        |> Ash.create()

      # Update with new guild_id (simulating upsert)
      updated_event = %{poll_vote_event | guild_id: generate_snowflake()}

      {:ok, second} =
        MessagePollVote
        |> Ash.Changeset.for_create(:from_discord, %{
          data: updated_event
        })
        |> Ash.create()

      # Should be the same record (upserted)
      assert first.id == second.id
      assert second.guild_id == updated_event.guild_id
    end

    test "allows multiple votes from same user for different answers" do
      user_id = generate_snowflake()
      message_id = generate_snowflake()

      vote1 =
        poll_vote_change_event(%{
          user_id: user_id,
          message_id: message_id,
          answer_id: 1
        })

      vote2 =
        poll_vote_change_event(%{
          user_id: user_id,
          message_id: message_id,
          answer_id: 2
        })

      {:ok, created1} =
        MessagePollVote
        |> Ash.Changeset.for_create(:from_discord, %{data: vote1})
        |> Ash.create()

      {:ok, created2} =
        MessagePollVote
        |> Ash.Changeset.for_create(:from_discord, %{data: vote2})
        |> Ash.create()

      # Should be different records
      assert created1.id != created2.id
      assert created1.answer_id == 1
      assert created2.answer_id == 2
    end

    test "handles identity map for identification" do
      identity = %{
        user_id: generate_snowflake(),
        message_id: generate_snowflake(),
        answer_id: 3
      }

      {:ok, created} =
        MessagePollVote
        |> Ash.Changeset.for_create(:from_discord, %{
          identity: identity
        })
        |> Ash.create()

      assert created.user_id == identity.user_id
      assert created.message_id == identity.message_id
      assert created.answer_id == identity.answer_id
    end

    test "errors when required identity fields are missing" do
      # Missing answer_id
      incomplete_identity = %{
        user_id: generate_snowflake(),
        message_id: generate_snowflake()
      }

      assert {:error, %Ash.Error.Invalid{}} =
               MessagePollVote
               |> Ash.Changeset.for_create(:from_discord, %{
                 identity: incomplete_identity
               })
               |> Ash.create()
    end

    test "errors when neither data nor identity provided" do
      assert {:error, %Ash.Error.Invalid{}} =
               MessagePollVote
               |> Ash.Changeset.for_create(:from_discord, %{})
               |> Ash.create()
    end
  end
end
