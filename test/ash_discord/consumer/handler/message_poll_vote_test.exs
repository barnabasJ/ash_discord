defmodule AshDiscord.Consumer.Handler.MessagePollVoteTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.MessagePollVote
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "add/3" do
    @tag :fixed
    test "creates poll vote from Discord event" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      author_data = user()
      voter_data = user()

      message_data =
        message(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          author: author_data
        })

      poll_vote_event =
        poll_vote_change_event(%{
          type: :add,
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          message_id: message_data.id,
          user_id: voter_data.id
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: voter_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      poll_vote_payload = Payloads.PollVoteChangeEvent.new!(poll_vote_event)

      assert :ok = MessagePollVote.add(poll_vote_payload, %Nostrum.Struct.WSState{}, context)

      [created_vote] =
        TestApp.Discord.MessagePollVote
        |> Ash.Query.load([:user, :message, :channel, :guild])
        |> Ash.read!(authorize?: false)

      assert created_vote.user.discord_id == poll_vote_event.user_id
      assert created_vote.message.discord_id == poll_vote_event.message_id
      assert created_vote.channel.discord_id == poll_vote_event.channel_id
      assert created_vote.guild.discord_id == poll_vote_event.guild_id
      assert created_vote.answer_id == poll_vote_event.answer_id
    end

    @tag :fixed
    test "handles upsert correctly for duplicate votes" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      author_data = user()
      voter_data = user()

      message_data =
        message(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          author: author_data
        })

      poll_vote_event =
        poll_vote_change_event(%{
          type: :add,
          answer_id: 1,
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          message_id: message_data.id,
          user_id: voter_data.id
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: voter_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      poll_vote_payload = Payloads.PollVoteChangeEvent.new!(poll_vote_event)

      assert :ok = MessagePollVote.add(poll_vote_payload, %Nostrum.Struct.WSState{}, context)
      assert :ok = MessagePollVote.add(poll_vote_payload, %Nostrum.Struct.WSState{}, context)

      assert [_] = TestApp.Discord.MessagePollVote.read!(authorize?: false)
    end

    @tag :fixed
    test "handles multiple votes for different answers" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      author_data = user()
      voter_data = user()

      message_data =
        message(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          author: author_data
        })

      vote1 =
        poll_vote_change_event(%{
          user_id: voter_data.id,
          message_id: message_data.id,
          channel_id: channel_data.id,
          guild_id: guild_data.id,
          answer_id: 1
        })

      vote2 =
        poll_vote_change_event(%{
          user_id: voter_data.id,
          message_id: message_data.id,
          channel_id: channel_data.id,
          guild_id: guild_data.id,
          answer_id: 2
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: voter_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      payload1 = Payloads.PollVoteChangeEvent.new!(vote1)
      payload2 = Payloads.PollVoteChangeEvent.new!(vote2)

      assert :ok = MessagePollVote.add(payload1, %Nostrum.Struct.WSState{}, context)
      assert :ok = MessagePollVote.add(payload2, %Nostrum.Struct.WSState{}, context)

      [vote_a, vote_b] =
        TestApp.Discord.MessagePollVote
        |> Ash.Query.load([:user, :message, :channel, :guild])
        |> Ash.read!(authorize?: false)

      assert vote_a.user.discord_id == voter_data.id
      assert vote_a.message.discord_id == message_data.id
      assert vote_a.channel.discord_id == channel_data.id
      assert vote_a.guild.discord_id == guild_data.id
      assert vote_b.user.discord_id == voter_data.id
      assert vote_b.message.discord_id == message_data.id
      assert vote_b.channel.discord_id == channel_data.id
      assert vote_b.guild.discord_id == guild_data.id
    end
  end

  describe "remove/3" do
    @tag :fixed
    test "removes poll vote by user_id, message_id, and answer_id" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      author_data = user()
      voter_data = user()

      message_data =
        message(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          author: author_data
        })

      poll_vote_event =
        poll_vote_change_event(%{
          type: :add,
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          message_id: message_data.id,
          user_id: voter_data.id
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: voter_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      TestApp.Discord.MessagePollVote
      |> Ash.Changeset.for_create(:from_discord, %{data: poll_vote_event})
      |> Ash.create!(authorize?: false)

      assert [_] = TestApp.Discord.MessagePollVote.read!(authorize?: false)

      remove_event = %{poll_vote_event | type: :remove}

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      remove_payload = Payloads.PollVoteChangeEvent.new!(remove_event)

      assert :ok = MessagePollVote.remove(remove_payload, %Nostrum.Struct.WSState{}, context)

      assert [] = TestApp.Discord.MessagePollVote.read!(authorize?: false)
    end

    @tag :fixed
    test "removes only matching vote when multiple exist" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})
      author_data = user()
      voter_data = user()

      message_data =
        message(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          author: author_data
        })

      vote1 =
        poll_vote_change_event(%{
          user_id: voter_data.id,
          message_id: message_data.id,
          channel_id: channel_data.id,
          guild_id: guild_data.id,
          answer_id: 1
        })

      vote2 =
        poll_vote_change_event(%{
          user_id: voter_data.id,
          message_id: message_data.id,
          channel_id: channel_data.id,
          guild_id: guild_data.id,
          answer_id: 2
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: author_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: voter_data}, authorize?: false)
      TestApp.Discord.message_from_discord!(%{data: message_data}, authorize?: false)

      TestApp.Discord.MessagePollVote
      |> Ash.Changeset.for_create(:from_discord, %{data: vote1})
      |> Ash.create!(authorize?: false)

      TestApp.Discord.MessagePollVote
      |> Ash.Changeset.for_create(:from_discord, %{data: vote2})
      |> Ash.create!(authorize?: false)

      assert [_, _] = TestApp.Discord.MessagePollVote.read!(authorize?: false)

      remove_event = %{vote1 | type: :remove}

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      remove_payload = Payloads.PollVoteChangeEvent.new!(remove_event)

      assert :ok = MessagePollVote.remove(remove_payload, %Nostrum.Struct.WSState{}, context)

      [remaining_vote] =
        TestApp.Discord.MessagePollVote
        |> Ash.Query.load([:user, :message, :channel, :guild])
        |> Ash.read!(authorize?: false)

      assert remaining_vote.answer_id == 2
      assert remaining_vote.user.discord_id == voter_data.id
      assert remaining_vote.message.discord_id == message_data.id
      assert remaining_vote.channel.discord_id == channel_data.id
      assert remaining_vote.guild.discord_id == guild_data.id
    end

    @tag :fixed
    test "handles removing non-existent vote gracefully" do
      poll_vote_event = poll_vote_change_event(%{type: :remove})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.MessagePollVote,
        guild: nil,
        user: nil,
        context: nil
      }

      poll_vote_payload = Payloads.PollVoteChangeEvent.new!(poll_vote_event)

      assert :ok = MessagePollVote.remove(poll_vote_payload, %Nostrum.Struct.WSState{}, context)
    end
  end
end
