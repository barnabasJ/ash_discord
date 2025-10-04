defmodule AshDiscord.Consumer.Handler.ReadyTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord
  import Mimic

  alias AshDiscord.Consumer.Handler.Ready
  alias TestApp.TestConsumer

  setup do
    copy(Nostrum.Api.ApplicationCommand)
    :ok
  end

  describe "ready/4" do
    test "registers global commands via API call" do
      ready_data = ready_event()

      expect(Nostrum.Api.ApplicationCommand, :bulk_overwrite_global_commands, fn commands ->
        assert is_list(commands)
        {:ok, []}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Ready.ready(TestConsumer, ready_data, %Nostrum.Struct.WSState{}, context)

      # Verify API was called (via expect above)
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
