defmodule AshDiscord.Changes.FromDiscord.InteractionTest do
  @moduledoc """
  Comprehensive tests for Interaction entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use ExUnit.Case, async: true
  import AshDiscord.Test.Generators.Discord

  setup do
    # Clear ETS tables before each test
    :ets.delete_all_objects(TestApp.Discord.Interaction)
    :ok
  end

  describe "struct-first pattern" do
    test "creates interaction from discord struct with all attributes" do
      interaction_struct =
        interaction(%{
          id: 123_456_789,
          application_id: 987_654_321,
          type: 2,
          data: %{
            id: 555_666_777,
            name: "test_command",
            type: 1
          },
          guild_id: 111_222_333,
          channel_id: 444_555_666,
          member: %{
            user: %{id: 777_888_999, username: "test_user"},
            nick: "TestNick"
          },
          user: nil,
          token: "interaction_token_abc123",
          version: 1,
          message: nil,
          app_permissions: "2048",
          locale: "en-US",
          guild_locale: "en-US"
        })

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: interaction_struct})

      assert {:ok, created_interaction} = result
      assert created_interaction.discord_id == interaction_struct.id
      assert created_interaction.application_id == interaction_struct.application_id
      assert created_interaction.type == interaction_struct.type
      assert created_interaction.guild_id == interaction_struct.guild_id
      assert created_interaction.channel_id == interaction_struct.channel_id
      assert created_interaction.token == interaction_struct.token
      assert created_interaction.version == interaction_struct.version
      assert created_interaction.app_permissions == interaction_struct.app_permissions
      assert created_interaction.locale == interaction_struct.locale
      assert created_interaction.guild_locale == interaction_struct.guild_locale
    end

    test "handles slash command interaction" do
      interaction_struct =
        interaction(%{
          id: 987_654_321,
          application_id: 123_456_789,
          # Slash command type
          type: 2,
          data: %{
            id: 111_222_333,
            name: "ping",
            type: 1,
            options: []
          },
          guild_id: 444_555_666,
          channel_id: 777_888_999,
          member: %{
            user: %{id: 333_444_555, username: "slash_user"},
            nick: nil
          },
          token: "slash_token_def456",
          version: 1
        })

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: interaction_struct})

      assert {:ok, created_interaction} = result
      assert created_interaction.discord_id == interaction_struct.id
      assert created_interaction.type == 2
    end

    test "handles message component interaction" do
      interaction_struct =
        interaction(%{
          id: 111_222_333,
          application_id: 777_888_999,
          # Message component type
          type: 3,
          data: %{
            custom_id: "button_click",
            component_type: 2
          },
          guild_id: 333_444_555,
          channel_id: 666_777_888,
          member: %{
            user: %{id: 999_111_222, username: "button_user"},
            nick: "ButtonClicker"
          },
          token: "component_token_ghi789",
          version: 1,
          message: %{
            id: 222_333_444,
            content: "Click the button!"
          }
        })

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: interaction_struct})

      assert {:ok, created_interaction} = result
      assert created_interaction.discord_id == interaction_struct.id
      assert created_interaction.type == 3
    end

    test "handles modal submit interaction" do
      interaction_struct =
        interaction(%{
          id: 444_555_666,
          application_id: 888_999_111,
          # Modal submit type
          type: 5,
          data: %{
            custom_id: "modal_submit",
            components: [
              %{
                type: 1,
                components: [
                  %{
                    type: 4,
                    custom_id: "text_input",
                    value: "User input text"
                  }
                ]
              }
            ]
          },
          guild_id: 555_666_777,
          channel_id: 111_222_333,
          member: %{
            user: %{id: 222_333_444, username: "modal_user"},
            nick: nil
          },
          token: "modal_token_jkl012",
          version: 1
        })

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: interaction_struct})

      assert {:ok, created_interaction} = result
      assert created_interaction.discord_id == interaction_struct.id
      assert created_interaction.type == 5
    end

    test "handles DM interaction without guild" do
      interaction_struct =
        interaction(%{
          id: 666_777_888,
          application_id: 999_111_222,
          type: 2,
          data: %{
            id: 333_444_555,
            name: "dm_command",
            type: 1
          },
          # No guild for DM
          guild_id: nil,
          channel_id: 777_888_999,
          # Direct user instead of member
          user: %{id: 111_222_333, username: "dm_user"},
          member: nil,
          token: "dm_token_mno345",
          version: 1,
          locale: "en-US"
        })

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: interaction_struct})

      assert {:ok, created_interaction} = result
      assert created_interaction.discord_id == interaction_struct.id
      assert created_interaction.guild_id == nil
    end

    test "handles interaction with app permissions" do
      interaction_struct =
        interaction(%{
          id: 777_888_999,
          application_id: 111_222_333,
          type: 2,
          data: %{
            id: 444_555_666,
            name: "admin_command",
            type: 1
          },
          guild_id: 888_999_111,
          channel_id: 222_333_444,
          member: %{
            user: %{id: 555_666_777, username: "admin_user"},
            nick: "Admin"
          },
          token: "admin_token_pqr678",
          version: 1,
          # Administrator permission
          app_permissions: "8"
        })

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: interaction_struct})

      assert {:ok, created_interaction} = result
      assert created_interaction.discord_id == interaction_struct.id
      assert created_interaction.app_permissions == "8"
    end

    test "handles interaction with locale information" do
      interaction_struct =
        interaction(%{
          id: 888_999_111,
          application_id: 222_333_444,
          type: 2,
          data: %{
            id: 666_777_888,
            name: "locale_command",
            type: 1
          },
          guild_id: 333_444_555,
          channel_id: 999_111_222,
          member: %{
            user: %{id: 444_555_666, username: "locale_user"},
            nick: nil
          },
          token: "locale_token_stu901",
          version: 1,
          locale: "fr",
          guild_locale: "en-US"
        })

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: interaction_struct})

      assert {:ok, created_interaction} = result
      assert created_interaction.discord_id == interaction_struct.id
      assert created_interaction.locale == "fr"
      assert created_interaction.guild_locale == "en-US"
    end
  end

  describe "API fallback pattern" do
    setup do
      Mimic.copy(Nostrum.Api)
      :ok
    end

    test "interaction API fallback is not supported" do
      # Interactions don't support direct API fetching in our implementation
      discord_id = 999_888_777

      result = TestApp.Discord.interaction_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      assert error.message =~ "Failed to fetch interaction with ID #{discord_id}"
      assert error.message =~ ":unsupported_type"
    end

    test "requires discord_struct for interaction creation" do
      result = TestApp.Discord.interaction_from_discord(%{})

      assert {:error, error} = result
      assert error.message =~ "No Discord ID found for interaction entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing interaction instead of creating duplicate" do
      discord_id = 555_666_777

      # Create initial interaction
      initial_struct =
        interaction(%{
          id: discord_id,
          application_id: 123_456_789,
          type: 2,
          data: %{
            id: 111_222_333,
            name: "original_command",
            type: 1
          },
          guild_id: 444_555_666,
          channel_id: 777_888_999,
          member: %{
            user: %{id: 987_654_321, username: "original_user"},
            nick: "Original"
          },
          token: "original_token",
          version: 1,
          locale: "en-US"
        })

      {:ok, original_interaction} =
        TestApp.Discord.interaction_from_discord(%{discord_struct: initial_struct})

      # Update same interaction with new data (hypothetical update)
      updated_struct =
        interaction(%{
          # Same ID
          id: discord_id,
          application_id: 123_456_789,
          type: 2,
          data: %{
            id: 111_222_333,
            name: "updated_command",
            type: 1
          },
          guild_id: 444_555_666,
          channel_id: 777_888_999,
          member: %{
            user: %{id: 987_654_321, username: "updated_user"},
            nick: "Updated"
          },
          token: "updated_token",
          version: 1,
          locale: "fr"
        })

      {:ok, updated_interaction} =
        TestApp.Discord.interaction_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_interaction.id == original_interaction.id
      assert updated_interaction.discord_id == original_interaction.discord_id

      # But with updated attributes
      assert updated_interaction.token == "updated_token"
      assert updated_interaction.locale == "fr"

      # Verify only one interaction record exists
      all_interactions = TestApp.Discord.Interaction.read!()

      interactions_with_discord_id =
        Enum.filter(all_interactions, &(&1.discord_id == discord_id))

      assert length(interactions_with_discord_id) == 1
    end

    test "upsert works with permission changes" do
      discord_id = 333_444_555

      # Create initial interaction without app permissions
      initial_struct =
        interaction(%{
          id: discord_id,
          application_id: 666_777_888,
          type: 2,
          data: %{
            id: 999_111_222,
            name: "perm_command",
            type: 1
          },
          guild_id: 222_333_444,
          channel_id: 555_666_777,
          member: %{
            user: %{id: 888_999_111, username: "perm_user"},
            nick: nil
          },
          token: "perm_token",
          version: 1,
          app_permissions: nil
        })

      {:ok, original_interaction} =
        TestApp.Discord.interaction_from_discord(%{discord_struct: initial_struct})

      # Update with app permissions
      updated_struct =
        interaction(%{
          # Same ID
          id: discord_id,
          application_id: 666_777_888,
          type: 2,
          data: %{
            id: 999_111_222,
            name: "perm_command",
            type: 1
          },
          guild_id: 222_333_444,
          channel_id: 555_666_777,
          member: %{
            user: %{id: 888_999_111, username: "perm_user"},
            nick: nil
          },
          token: "perm_token",
          version: 1,
          app_permissions: "2048"
        })

      {:ok, updated_interaction} =
        TestApp.Discord.interaction_from_discord(%{discord_struct: updated_struct})

      # Should be same record
      assert updated_interaction.id == original_interaction.id
      assert updated_interaction.discord_id == discord_id

      # But with updated permissions
      assert updated_interaction.app_permissions == "2048"

      # Verify only one interaction record exists
      all_interactions = TestApp.Discord.Interaction.read!()

      interactions_with_discord_id =
        Enum.filter(all_interactions, &(&1.discord_id == discord_id))

      assert length(interactions_with_discord_id) == 1
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.interaction_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = %{}

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles invalid interaction type" do
      interaction_struct =
        interaction(%{
          id: 123_456_789,
          application_id: 987_654_321,
          # Invalid type
          type: 999,
          data: %{
            id: 555_666_777,
            name: "test_command",
            type: 1
          },
          guild_id: 111_222_333,
          channel_id: 444_555_666,
          token: "test_token",
          version: 1
        })

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: interaction_struct})

      # This might succeed with normalized type or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_interaction} ->
          # If it succeeds, type should be handled gracefully
          assert created_interaction.discord_id == interaction_struct.id

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end

    test "handles malformed interaction data" do
      malformed_struct = %{
        id: "not_an_integer",
        application_id: "not_an_integer",
        # Required field as nil
        type: nil,
        token: nil
      }

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: malformed_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      # Should contain validation errors
      assert error_message =~ "is required" or error_message =~ "is invalid"
    end

    test "handles missing token in discord_struct" do
      invalid_struct = %{
        id: 123_456_789,
        application_id: 987_654_321,
        type: 2,
        # Missing token field
        guild_id: 111_222_333,
        channel_id: 444_555_666
      }

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required" or error_message =~ "token"
    end
  end
end
