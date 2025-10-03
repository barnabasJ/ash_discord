defmodule AshDiscord.Consumer.Handler.InteractionTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord
  import Mimic

  alias AshDiscord.Consumer.Handler.Interaction
  alias TestApp.TestConsumer

  setup do
    copy(Nostrum.Api.Interaction)
    :ok
  end

  describe "create/3" do
    test "handles application command interaction" do
      interaction_data =
        interaction(%{
          type: 2,
          data: %{name: "hello", options: []}
        })

      expect(Nostrum.Api.Interaction, :create_response, fn _interaction_id, _token, _response ->
        {:ok}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      # The handler routes to the interaction router which stores in process dict
      _result = Interaction.create(interaction_data, %Nostrum.Struct.WSState{}, context)

      # Interaction should be processed without error
      # The actual result depends on command routing which is tested elsewhere
    end

    test "handles non-application command interaction types" do
      # Button interaction (type 3)
      interaction_data = interaction(%{type: 3})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok = Interaction.create(interaction_data, %Nostrum.Struct.WSState{}, context)
    end

    test "handles known command successfully" do
      interaction_data =
        interaction(%{
          type: 2,
          data: %{name: "hello", options: []}
        })

      expect(Nostrum.Api.Interaction, :create_response, fn interaction_id, token, response ->
        assert interaction_id == interaction_data.id
        assert token == interaction_data.token
        # Success response
        assert response.type == 4
        {:ok}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      Interaction.create(interaction_data, %Nostrum.Struct.WSState{}, context)
    end
  end
end
