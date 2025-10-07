defmodule AshDiscord.Changes.FromDiscord.IntegrationTest do
  @moduledoc """
  Tests for Integration entity from_discord transformation.

  Tests struct-first pattern and upsert behavior.
  Note: Integrations don't support API fallback as they can only be retrieved
  via guild-level API calls, not individual lookups.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators

  describe "struct-first pattern" do
    test "creates integration from discord struct with all attributes" do
      account = integration_account(%{id: "account123", name: "Test Account"})

      application =
        integration_application(%{
          id: 999_888_777,
          name: "Test Bot",
          icon: "icon_hash",
          description: "A test bot",
          summary: "Test summary"
        })

      integration_struct =
        integration(%{
          id: 123_456_789,
          name: "Discord Bot",
          type: "discord",
          enabled: true,
          guild_id: 555_666_777,
          account: account,
          application: application
        })

      {:ok, payload} = AshDiscord.Consumer.Payloads.Integration.new(integration_struct)

      result =
        TestApp.Discord.Integration
        |> Ash.Changeset.for_create(:from_discord, %{
          data: payload,
          identity: %{
            integration_id: integration_struct.id,
            guild_id: integration_struct.guild_id
          }
        })
        |> Ash.create()

      assert {:ok, created_integration} = result
      assert created_integration.discord_id == integration_struct.id
      assert created_integration.name == integration_struct.name
      assert created_integration.type == "discord"
      assert created_integration.enabled == true
      assert created_integration.guild_id == 555_666_777
      assert created_integration.account_id == "account123"
      assert created_integration.account_name == "Test Account"
      assert created_integration.application_id == 999_888_777
      assert created_integration.application_name == "Test Bot"
    end

    test "handles integration without application (non-Discord type)" do
      account = integration_account(%{id: "twitch_account", name: "Twitch User"})

      integration_struct =
        integration(%{
          id: 123_456_789,
          name: "Twitch Stream",
          type: "twitch",
          enabled: true,
          guild_id: 555_666_777,
          account: account,
          application: nil
        })

      {:ok, payload} = AshDiscord.Consumer.Payloads.Integration.new(integration_struct)

      result =
        TestApp.Discord.Integration
        |> Ash.Changeset.for_create(:from_discord, %{
          data: payload,
          identity: %{
            integration_id: integration_struct.id,
            guild_id: integration_struct.guild_id
          }
        })
        |> Ash.create()

      assert {:ok, created_integration} = result
      assert created_integration.discord_id == integration_struct.id
      assert created_integration.name == "Twitch Stream"
      assert created_integration.type == "twitch"
      assert created_integration.account_id == "twitch_account"
      assert created_integration.account_name == "Twitch User"
      assert created_integration.application_id == nil
      assert created_integration.application_name == nil
    end

    test "handles disabled integration" do
      integration_struct =
        integration(%{
          id: 123_456_789,
          name: "Disabled Integration",
          type: "youtube",
          enabled: false,
          guild_id: 555_666_777
        })

      {:ok, payload} = AshDiscord.Consumer.Payloads.Integration.new(integration_struct)

      result =
        TestApp.Discord.Integration
        |> Ash.Changeset.for_create(:from_discord, %{
          data: payload,
          identity: %{
            integration_id: integration_struct.id,
            guild_id: integration_struct.guild_id
          }
        })
        |> Ash.create()

      assert {:ok, created_integration} = result
      assert created_integration.enabled == false
      assert created_integration.type == "youtube"
    end
  end

  describe "upsert behavior" do
    test "updates existing integration on create" do
      integration_struct = integration(%{id: 123_456_789, name: "Original Name", enabled: true})

      {:ok, payload} = AshDiscord.Consumer.Payloads.Integration.new(integration_struct)

      # Create initial integration
      {:ok, original} =
        TestApp.Discord.Integration
        |> Ash.Changeset.for_create(:from_discord, %{
          data: payload,
          identity: %{
            integration_id: integration_struct.id,
            guild_id: integration_struct.guild_id
          }
        })
        |> Ash.create()

      # Update with same discord_id
      updated_struct =
        integration(%{
          id: 123_456_789,
          name: "Updated Name",
          enabled: false,
          guild_id: integration_struct.guild_id,
          account: integration_struct.account,
          application: integration_struct.application
        })

      {:ok, updated_payload} = AshDiscord.Consumer.Payloads.Integration.new(updated_struct)

      {:ok, updated} =
        TestApp.Discord.Integration
        |> Ash.Changeset.for_create(:from_discord, %{
          data: updated_payload,
          identity: %{integration_id: updated_struct.id, guild_id: updated_struct.guild_id}
        })
        |> Ash.create()

      # Should be same record
      assert updated.id == original.id
      assert updated.discord_id == 123_456_789
      assert updated.name == "Updated Name"
      assert updated.enabled == false

      # Verify only one record exists
      all_integrations = TestApp.Discord.Integration.read!()
      assert length(all_integrations) == 1
    end
  end

  describe "error handling" do
    test "returns error when data is nil" do
      result =
        TestApp.Discord.Integration
        |> Ash.Changeset.for_create(:from_discord, %{
          data: nil,
          identity: %{integration_id: 123, guild_id: 456}
        })
        |> Ash.create()

      assert {:error, %Ash.Error.Invalid{}} = result
    end

    test "returns error when data is invalid type" do
      result =
        TestApp.Discord.Integration
        |> Ash.Changeset.for_create(:from_discord, %{
          data: "not a struct",
          identity: %{integration_id: 123, guild_id: 456}
        })
        |> Ash.create()

      assert {:error, %Ash.Error.Invalid{}} = result
    end
  end
end
