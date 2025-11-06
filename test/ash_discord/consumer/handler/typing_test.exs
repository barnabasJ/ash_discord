defmodule AshDiscord.Consumer.Handler.TypingTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Typing
  alias TestApp.TestConsumer

  describe "start/3" do
    @tag :fixed
    test "creates typing indicator in database with all relationships" do
      # Create prerequisite records for all relationships
      guild_data = guild()
      user_data = user()
      channel_data = channel(%{guild_id: guild_data.id})

      typing_data =
        typing_indicator(%{
          guild_id: guild_data.id,
          user_id: user_data.id,
          channel_id: channel_data.id
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.TypingIndicator,
        guild: nil,
        user: nil
      }

      assert :ok = Typing.start(typing_data, %Nostrum.Struct.WSState{}, context)

      [created_indicator] =
        TestApp.Discord.TypingIndicator
        |> Ash.Query.load([:user, :channel, :guild])
        |> Ash.read!(authorize?: false)

      assert created_indicator.user.discord_id == typing_data.user_id
      assert created_indicator.channel.discord_id == typing_data.channel_id
      assert created_indicator.guild.discord_id == typing_data.guild_id
      assert created_indicator.timestamp != nil
    end
  end
end
