defmodule AshDiscord.Consumer.Handler.ResumedTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators
  use Mimic

  alias AshDiscord.Consumer.Handler.Resumed
  alias TestApp.TestConsumer

  setup do
    :ok
  end

  describe "ready/4" do
    @tag :fixed
    test "registers global commands via API call" do
      ready_data = resumed_event()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Event,
        guild: nil,
        user: nil
      }

      log =
      ExUnit.CaptureLog.capture_log(fn ->
        assert :ok =
                 Resumed.resumed(TestConsumer, ready_data, %Nostrum.Struct.WSState{}, context)
      end) 

      assert log =~ "Resumed action invoked"
    end
  end
end
