defmodule AshDiscord.Changes.FromDiscord.MessagePollVoteTest do
  @moduledoc """
  Comprehensive tests for MessagePollVote entity from_discord transformation.

  Tests event-based creation pattern and upsert behavior.

  Note: Poll votes are event-only data and cannot be fetched from Discord API.
  Only the data argument is supported - no identity-based creation or API fallback.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators

  describe "event-based creation" do
    @tag :fixed
    test "creates poll vote from discord struct with all attributes" do
      user_id = 111_222_333
      message_id = 444_555_666
      channel_id = 777_888_999
      guild_id = 123_456_789

      poll_vote_event =
        poll_vote_change_event(%{
          user_id: user_id,
          message_id: message_id,
          channel_id: channel_id,
          guild_id: guild_id,
          answer_id: 1,
          type: :add
        })

      created =
        TestApp.Discord.message_poll_vote_from_discord!(%{data: poll_vote_event})

      assert created.user_discord_id == user_id
      assert created.message_discord_id == message_id
      assert created.channel_discord_id == channel_id
      assert created.guild_discord_id == guild_id
      assert created.answer_id == 1
    end

    @tag :fixed
    test "handles different answer IDs" do
      user_id = 999_888_777
      message_id = 555_444_333

      poll_vote_event =
        poll_vote_change_event(%{
          user_id: user_id,
          message_id: message_id,
          channel_id: 111_111_111,
          guild_id: 222_222_222,
          answer_id: 5,
          type: :add
        })

      created =
        TestApp.Discord.message_poll_vote_from_discord!(%{data: poll_vote_event})

      assert created.user_discord_id == user_id
      assert created.message_discord_id == message_id
      assert created.answer_id == 5
    end

    @tag :fixed
    test "handles remove vote type" do
      poll_vote_event =
        poll_vote_change_event(%{
          user_id: 111_111_111,
          message_id: 222_222_222,
          channel_id: 333_333_333,
          guild_id: 444_444_444,
          answer_id: 2,
          type: :remove
        })

      created =
        TestApp.Discord.message_poll_vote_from_discord!(%{data: poll_vote_event})

      assert created.user_discord_id == 111_111_111
      assert created.message_discord_id == 222_222_222
      assert created.answer_id == 2
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing poll vote instead of creating duplicate" do
      user_id = 111_222_333
      message_id = 444_555_666
      answer_id = 1

      initial_event =
        poll_vote_change_event(%{
          user_id: user_id,
          message_id: message_id,
          channel_id: 777_777_777,
          guild_id: 888_888_888,
          answer_id: answer_id,
          type: :add
        })

      original =
        TestApp.Discord.message_poll_vote_from_discord!(%{data: initial_event})

      updated_event =
        poll_vote_change_event(%{
          user_id: user_id,
          message_id: message_id,
          channel_id: 999_999_999,
          guild_id: 111_111_111,
          answer_id: answer_id,
          type: :add
        })

      updated =
        TestApp.Discord.message_poll_vote_from_discord!(%{data: updated_event})

      assert updated.id == original.id
      assert updated.user_discord_id == original.user_discord_id
      assert updated.message_discord_id == original.message_discord_id
      assert updated.answer_id == original.answer_id

      assert updated.channel_discord_id == 999_999_999
      assert updated.guild_discord_id == 111_111_111
    end

    @tag :fixed
    test "allows multiple votes from same user for different answers" do
      user_id = 555_666_777
      message_id = 888_999_000

      vote1 =
        poll_vote_change_event(%{
          user_id: user_id,
          message_id: message_id,
          channel_id: 111_222_333,
          guild_id: 444_555_666,
          answer_id: 1,
          type: :add
        })

      vote2 =
        poll_vote_change_event(%{
          user_id: user_id,
          message_id: message_id,
          channel_id: 111_222_333,
          guild_id: 444_555_666,
          answer_id: 2,
          type: :add
        })

      created1 =
        TestApp.Discord.message_poll_vote_from_discord!(%{data: vote1})

      created2 =
        TestApp.Discord.message_poll_vote_from_discord!(%{data: vote2})

      assert created1.id != created2.id
      assert created1.user_discord_id == user_id
      assert created2.user_discord_id == user_id
      assert created1.answer_id == 1
      assert created2.answer_id == 2
    end

    @tag :fixed
    test "allows multiple users to vote for same answer" do
      message_id = 123_456_789
      answer_id = 1

      vote1 =
        poll_vote_change_event(%{
          user_id: 111_111_111,
          message_id: message_id,
          channel_id: 777_888_999,
          guild_id: 555_666_777,
          answer_id: answer_id,
          type: :add
        })

      vote2 =
        poll_vote_change_event(%{
          user_id: 222_222_222,
          message_id: message_id,
          channel_id: 777_888_999,
          guild_id: 555_666_777,
          answer_id: answer_id,
          type: :add
        })

      created1 =
        TestApp.Discord.message_poll_vote_from_discord!(%{data: vote1})

      created2 =
        TestApp.Discord.message_poll_vote_from_discord!(%{data: vote2})

      assert created1.id != created2.id
      assert created1.user_discord_id == 111_111_111
      assert created2.user_discord_id == 222_222_222
      assert created1.answer_id == answer_id
      assert created2.answer_id == answer_id
    end
  end
end
