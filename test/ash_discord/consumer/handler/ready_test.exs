defmodule AshDiscord.Consumer.Handler.ReadyTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators
  use Mimic

  alias AshDiscord.Consumer.Handler.Ready
  alias TestApp.TestConsumer

  setup do
    copy(Nostrum.Api.ApplicationCommand)
    :ok
  end

  describe "ready/4" do
    test "registers global commands via API call" do
      ready_data = ready_event()

      # TestConsumer has no commands configured, so API should NOT be called
      reject(&Nostrum.Api.ApplicationCommand.bulk_overwrite_global_commands/1)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Ready.ready(TestConsumer, ready_data, %Nostrum.Struct.WSState{}, context)
    end

    test "handles empty commands list" do
      ready_data = ready_event()

      # Should not call API when no commands exist
      reject(&Nostrum.Api.ApplicationCommand.bulk_overwrite_global_commands/1)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Ready.ready(TestConsumer, ready_data, %Nostrum.Struct.WSState{}, context)
    end
  end
end
