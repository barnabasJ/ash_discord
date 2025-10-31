defmodule AshDiscord.Changes.FromDiscord.IntegrationTest do
  @moduledoc """
  Comprehensive tests for Integration entity from_discord transformation.

  Tests struct-first pattern and upsert behavior.
  No API fallback pattern - integrations can only be retrieved via guild-level API calls.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates integration from discord struct with all attributes" do
      guild_id = 555_666_777

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

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
          guild_id: guild_id,
          account: account,
          application: application
        })

      {:ok, payload} = AshDiscord.Consumer.Payloads.Integration.new(integration_struct)

      created_integration =
        TestApp.Discord.integration_from_discord!(
          %{
            data: payload,
            identity: %{
              integration_id: integration_struct.id,
              guild_id: integration_struct.guild_id
            }
          },
          load: [:guild]
        )

      assert created_integration.discord_id == integration_struct.id
      assert created_integration.name == integration_struct.name
      assert created_integration.type == "discord"
      assert created_integration.enabled == true
      assert created_integration.account_discord_id == "account123"
      assert created_integration.account_name == "Test Account"
      assert created_integration.application_discord_id == 999_888_777
      assert created_integration.application_name == "Test Bot"
      assert created_integration.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles integration without application (non-Discord type)" do
      guild_id = 555_666_777

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      account = integration_account(%{id: "twitch_account", name: "Twitch User"})

      integration_struct =
        integration(%{
          id: 123_456_789,
          name: "Twitch Stream",
          type: "twitch",
          enabled: true,
          guild_id: guild_id,
          account: account,
          application: nil
        })

      {:ok, payload} = AshDiscord.Consumer.Payloads.Integration.new(integration_struct)

      created_integration =
        TestApp.Discord.integration_from_discord!(
          %{
            data: payload,
            identity: %{
              integration_id: integration_struct.id,
              guild_id: integration_struct.guild_id
            }
          },
          load: [:guild]
        )

      assert created_integration.discord_id == integration_struct.id
      assert created_integration.name == "Twitch Stream"
      assert created_integration.type == "twitch"
      assert created_integration.account_discord_id == "twitch_account"
      assert created_integration.account_name == "Twitch User"
      assert created_integration.application_discord_id == nil
      assert created_integration.application_name == nil
      assert created_integration.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles disabled integration" do
      guild_id = 555_666_777

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      integration_struct =
        integration(%{
          id: 123_456_789,
          name: "Disabled Integration",
          type: "youtube",
          enabled: false,
          guild_id: guild_id
        })

      {:ok, payload} = AshDiscord.Consumer.Payloads.Integration.new(integration_struct)

      created_integration =
        TestApp.Discord.integration_from_discord!(
          %{
            data: payload,
            identity: %{
              integration_id: integration_struct.id,
              guild_id: integration_struct.guild_id
            }
          },
          load: [:guild]
        )

      assert created_integration.enabled == false
      assert created_integration.type == "youtube"
      assert created_integration.guild.discord_id == guild_id
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing integration instead of creating duplicate" do
      guild_id = 555_666_777

      expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      integration_struct =
        integration(%{
          id: 123_456_789,
          name: "Original Name",
          enabled: true,
          guild_id: guild_id
        })

      {:ok, payload} = AshDiscord.Consumer.Payloads.Integration.new(integration_struct)

      original =
        TestApp.Discord.integration_from_discord!(%{
          data: payload,
          identity: %{
            integration_id: integration_struct.id,
            guild_id: integration_struct.guild_id
          }
        })

      updated_struct =
        integration(%{
          id: 123_456_789,
          name: "Updated Name",
          enabled: false,
          guild_id: guild_id,
          account: integration_struct.account,
          application: integration_struct.application
        })

      {:ok, updated_payload} = AshDiscord.Consumer.Payloads.Integration.new(updated_struct)

      updated =
        TestApp.Discord.integration_from_discord!(%{
          data: updated_payload,
          identity: %{integration_id: updated_struct.id, guild_id: updated_struct.guild_id}
        })

      assert updated.id == original.id
      assert updated.discord_id == 123_456_789
      assert updated.name == "Updated Name"
      assert updated.enabled == false
    end
  end
end
