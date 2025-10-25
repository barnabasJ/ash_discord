defmodule AshDiscord.Consumer.Handler.IntegrationTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Integration
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    @tag :fixed
    test "creates integration in database" do
      guild_data = guild()
      integration_data = integration(%{guild_id: guild_data.id})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Integration,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      integration_payload = Payloads.Integration.new!(integration_data)

      assert :ok =
               Integration.create(
                 integration_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [created_integration] =
        TestApp.Discord.Integration
        |> Ash.Query.load([:guild])
        |> Ash.read!(authorize?: false)

      assert created_integration.discord_id == integration_data.id
      assert created_integration.name == integration_data.name
      assert created_integration.type == integration_data.type
      assert created_integration.enabled == integration_data.enabled
      assert created_integration.guild.discord_id == integration_data.guild_id
      assert created_integration.account_id == integration_data.account.id
      assert created_integration.account_name == integration_data.account.name
      assert created_integration.application_id == integration_data.application.id
      assert created_integration.application_name == integration_data.application.name
    end
  end

  describe "update/3" do
    @tag :fixed
    test "updates existing integration in database" do
      guild_data = guild()

      old_integration =
        integration(%{guild_id: guild_data.id, name: "Old Integration", enabled: true})

      new_integration =
        integration(%{
          id: old_integration.id,
          guild_id: guild_data.id,
          name: "New Integration",
          enabled: false
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Integration,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      new_integration_payload = Payloads.Integration.new!(new_integration)

      assert :ok =
               Integration.update(
                 new_integration_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [updated_integration] =
        TestApp.Discord.Integration
        |> Ash.Query.load([:guild])
        |> Ash.read!(authorize?: false)

      assert updated_integration.discord_id == new_integration.id
      assert updated_integration.name == "New Integration"
      assert updated_integration.enabled == false
      assert updated_integration.guild.discord_id == new_integration.guild_id
    end
  end

  describe "delete/3" do
    @tag :fixed
    test "deletes integration from database" do
      guild_data = guild()
      integration_data = integration(%{guild_id: guild_data.id})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)

      integration_payload = Payloads.Integration.new!(integration_data)

      {:ok, _created} =
        TestApp.Discord.Integration
        |> Ash.Changeset.for_create(:from_discord, %{
          data: integration_payload,
          identity: %{integration_id: integration_data.id, guild_id: integration_data.guild_id}
        })
        |> Ash.create(authorize?: false)

      assert [_integration] = TestApp.Discord.Integration.read!(authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Integration,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      delete_event =
        integration_delete_event(%{
          id: integration_data.id,
          guild_id: integration_data.guild_id
        })

      delete_payload = Payloads.IntegrationDelete.new!(delete_event)

      assert :ok =
               Integration.delete(
                 delete_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )

      assert [] = TestApp.Discord.Integration.read!(authorize?: false)
    end

    @tag :fixed
    test "handles deleting non-existent integration" do
      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Integration,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      delete_event = integration_delete_event()
      delete_payload = Payloads.IntegrationDelete.new!(delete_event)

      assert :ok =
               Integration.delete(
                 delete_payload,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end
end
