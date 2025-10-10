defmodule AshDiscord.Consumer.Handler.ReadyTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators
  use Mimic

  alias AshDiscord.Consumer.Handler.Ready
  alias TestApp.TestConsumer

  describe "ready/4" do
    # TODO: actually test the command registration
    @tag :fixed
    test "registers global commands via API call" do
      ready_data = ready_event()

      reject(&Nostrum.Api.ApplicationCommand.bulk_overwrite_global_commands/1)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Event,
        guild: nil,
        user: nil
      }

      log =
        ExUnit.CaptureLog.capture_log(fn ->
          assert :ok =
                   assert(:ok = Ready.ready(ready_data, %Nostrum.Struct.WSState{}, context))
        end)

      assert log =~ "action invoked"
    end
  end
end
