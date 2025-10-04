defmodule AshDiscord.Consumer.Handler.TypingTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Consumer.Handler.Typing
  alias TestApp.TestConsumer

  describe "start/4" do
    test "creates typing indicator in database" do
      typing_data = typing_indicator()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Typing.start(TestConsumer, typing_data, %Nostrum.Struct.WSState{}, context)

      # Verify typing indicator was created in database
      indicators = TestApp.Discord.TypingIndicator.read!()
      assert length(indicators) == 1

      created_indicator = hd(indicators)
      assert created_indicator.user_id == typing_data.user_id
      assert created_indicator.channel_id == typing_data.channel_id
    end
  end
end
