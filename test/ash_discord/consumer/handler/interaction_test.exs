defmodule AshDiscord.Consumer.Handler.InteractionTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators
  use Mimic

  alias AshDiscord.Consumer.Handler.Interaction
  alias TestApp.TestConsumer

  setup do
    copy(Nostrum.Api.Interaction)
    :ok
  end

  describe "create/3" do
    @tag :fixed
    test "routes application command to interaction router" do
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

      assert {:ok, response} =
               Interaction.create(interaction_data, %Nostrum.Struct.WSState{}, context)

      assert is_map(response)
    end

    @tag :fixed
    test "handles non-application command interaction types" do
      interaction_data = interaction(%{type: 3})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok = Interaction.create(interaction_data, %Nostrum.Struct.WSState{}, context)
    end

    @tag :fixed
    test "sends error response for unknown command" do
      interaction_data =
        interaction(%{
          type: 2,
          data: %{name: "unknown_command", options: []}
        })

      expect(Nostrum.Api.Interaction, :create_response, fn interaction_id, token, response ->
        assert interaction_id == interaction_data.id
        assert token == interaction_data.token
        assert response.type == 4
        assert response.data.flags == 64
        {:ok}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok = Interaction.create(interaction_data, %Nostrum.Struct.WSState{}, context)
    end
  end
end
