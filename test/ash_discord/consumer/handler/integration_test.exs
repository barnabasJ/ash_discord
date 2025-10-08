defmodule AshDiscord.Consumer.Handler.IntegrationTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Integration
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    test "creates integration in database" do
      integration_data = integration()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Integration,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      {:ok, integration_payload} = Payloads.Integration.new(integration_data)

      assert :ok =
               Integration.create(
                 integration_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify integration was created in database
      integrations = TestApp.Discord.Integration.read!()
      assert length(integrations) == 1

      created_integration = hd(integrations)
      assert created_integration.discord_id == integration_data.id
      assert created_integration.name == integration_data.name
      assert created_integration.type == integration_data.type
      assert created_integration.enabled == integration_data.enabled
      assert created_integration.guild_id == integration_data.guild_id
      assert created_integration.account_id == integration_data.account.id
      assert created_integration.account_name == integration_data.account.name
      assert created_integration.application_id == integration_data.application.id
      assert created_integration.application_name == integration_data.application.name
    end
  end

  describe "update/3" do
    test "updates existing integration in database" do
      old_integration = integration(%{name: "Old Integration", enabled: true})

      new_integration =
        integration(%{id: old_integration.id, name: "New Integration", enabled: false})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Integration,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      {:ok, new_integration_payload} = Payloads.Integration.new(new_integration)

      assert :ok =
               Integration.update(
                 new_integration_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify integration was updated (upserted) in database
      integrations = TestApp.Discord.Integration.read!()
      assert length(integrations) == 1

      updated_integration = hd(integrations)
      assert updated_integration.discord_id == new_integration.id
      assert updated_integration.name == "New Integration"
      assert updated_integration.enabled == false
      assert updated_integration.guild_id == new_integration.guild_id
    end
  end

  describe "delete/3" do
    test "deletes integration from database" do
      integration_data = integration()

      # First create the integration
      {:ok, integration_payload} = Payloads.Integration.new(integration_data)

      {:ok, _created} =
        TestApp.Discord.Integration
        |> Ash.Changeset.for_create(:from_discord, %{
          data: integration_payload,
          identity: %{integration_id: integration_data.id, guild_id: integration_data.guild_id}
        })
        |> Ash.create()

      # Verify it was created
      assert length(TestApp.Discord.Integration.read!()) == 1

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Integration,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      # Create delete event
      delete_event =
        integration_delete_event(%{
          id: integration_data.id,
          guild_id: integration_data.guild_id
        })

      {:ok, delete_payload} = Payloads.IntegrationDelete.new(delete_event)

      assert :ok =
               Integration.delete(
                 delete_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify integration was deleted
      assert length(TestApp.Discord.Integration.read!()) == 0
    end

    test "handles deleting non-existent integration" do
      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Integration,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      delete_event = integration_delete_event()
      {:ok, delete_payload} = Payloads.IntegrationDelete.new(delete_event)

      # Should succeed even if integration doesn't exist
      assert :ok =
               Integration.delete(
                 delete_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end
end
