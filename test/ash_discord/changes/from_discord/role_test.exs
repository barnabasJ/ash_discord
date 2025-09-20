defmodule AshDiscord.Changes.FromDiscord.RoleTest do
  @moduledoc """
  Comprehensive tests for Role entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use ExUnit.Case, async: true
  import AshDiscord.Test.Generators.Discord

  setup do
    # Clear ETS tables before each test
    :ets.delete_all_objects(TestApp.Discord.Role)
    :ok
  end

  describe "struct-first pattern" do
    test "creates role from discord struct with all attributes" do
      role_struct =
        role(%{
          id: 123_456_789,
          name: "Test Role",
          color: 16_711_680,
          hoist: true,
          position: 5,
          permissions: 2048,
          managed: false,
          mentionable: true,
          guild_id: 555_666_777
        })

      result = TestApp.Discord.role_from_discord(%{discord_struct: role_struct})

      assert {:ok, created_role} = result
      assert created_role.discord_id == role_struct.id
      assert created_role.name == role_struct.name
      assert created_role.color == role_struct.color
      assert created_role.hoist == true
      assert created_role.position == role_struct.position
      assert created_role.permissions == role_struct.permissions
      assert created_role.managed == false
      assert created_role.mentionable == true
      assert created_role.guild_id == role_struct.guild_id
    end

    test "handles default role (@everyone)" do
      guild_id = 555_666_777

      role_struct =
        role(%{
          # Default role has same ID as guild
          id: guild_id,
          name: "@everyone",
          color: 0,
          hoist: false,
          position: 0,
          permissions: 104_324_161,
          managed: false,
          mentionable: false,
          guild_id: guild_id
        })

      result = TestApp.Discord.role_from_discord(%{discord_struct: role_struct})

      assert {:ok, created_role} = result
      assert created_role.discord_id == guild_id
      assert created_role.name == "@everyone"
      assert created_role.color == 0
      assert created_role.hoist == false
      assert created_role.position == 0
    end

    test "handles managed bot role" do
      role_struct =
        role(%{
          id: 777_888_999,
          name: "Bot Role",
          color: 5_793_266,
          hoist: true,
          position: 10,
          permissions: 8,
          managed: true,
          mentionable: false,
          guild_id: 111_222_333
        })

      result = TestApp.Discord.role_from_discord(%{discord_struct: role_struct})

      assert {:ok, created_role} = result
      assert created_role.discord_id == role_struct.id
      assert created_role.name == role_struct.name
      assert created_role.managed == true
      assert created_role.mentionable == false
    end

    test "handles high permission role" do
      role_struct =
        role(%{
          id: 333_444_555,
          name: "Admin",
          color: 15_158_332,
          hoist: true,
          position: 20,
          # Administrator permission
          permissions: 8,
          managed: false,
          mentionable: true
        })

      result = TestApp.Discord.role_from_discord(%{discord_struct: role_struct})

      assert {:ok, created_role} = result
      assert created_role.discord_id == role_struct.id
      assert created_role.name == role_struct.name
      assert created_role.permissions == 8
    end
  end

  describe "API fallback pattern" do
    setup do
      Mimic.copy(Nostrum.Api)
      :ok
    end

    test "role API fallback is not supported" do
      # Roles don't support direct API fetching in our implementation
      discord_id = 999_888_777

      result = TestApp.Discord.role_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      assert error.message =~ "Failed to fetch role with ID #{discord_id}"
      assert error.message =~ ":unsupported_type"
    end

    test "requires discord_struct for role creation" do
      result = TestApp.Discord.role_from_discord(%{})

      assert {:error, error} = result
      assert error.message =~ "No Discord ID found for role entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing role instead of creating duplicate" do
      discord_id = 555_666_777

      # Create initial role
      initial_struct =
        role(%{
          id: discord_id,
          name: "Original Role",
          color: 255,
          hoist: false,
          position: 1,
          permissions: 1024
        })

      {:ok, original_role} = TestApp.Discord.role_from_discord(%{discord_struct: initial_struct})

      # Update same role with new data
      updated_struct =
        role(%{
          # Same ID
          id: discord_id,
          name: "Updated Role",
          color: 65_280,
          hoist: true,
          position: 5,
          permissions: 2048,
          mentionable: true
        })

      {:ok, updated_role} = TestApp.Discord.role_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_role.id == original_role.id
      assert updated_role.discord_id == original_role.discord_id

      # But with updated attributes
      assert updated_role.name == "Updated Role"
      assert updated_role.color == 65_280
      assert updated_role.hoist == true
      assert updated_role.position == 5
      assert updated_role.permissions == 2048
      assert updated_role.mentionable == true

      # Verify only one role record exists
      all_roles = TestApp.Discord.Role.read!()
      roles_with_discord_id = Enum.filter(all_roles, &(&1.discord_id == discord_id))
      assert length(roles_with_discord_id) == 1
    end

    test "upsert works with permission changes" do
      discord_id = 333_444_555

      # Create initial role with basic permissions
      initial_struct =
        role(%{
          id: discord_id,
          name: "Member Role",
          permissions: 104_324_161,
          managed: false
        })

      {:ok, original_role} = TestApp.Discord.role_from_discord(%{discord_struct: initial_struct})

      # Update with admin permissions
      updated_struct =
        role(%{
          # Same ID
          id: discord_id,
          name: "Member Role",
          # Administrator permission
          permissions: 8,
          managed: false
        })

      {:ok, updated_role} = TestApp.Discord.role_from_discord(%{discord_struct: updated_struct})

      # Should be same record
      assert updated_role.id == original_role.id
      assert updated_role.discord_id == discord_id

      # But with updated permissions
      assert updated_role.permissions == 8

      # Verify only one role record exists
      all_roles = TestApp.Discord.Role.read!()
      roles_with_discord_id = Enum.filter(all_roles, &(&1.discord_id == discord_id))
      assert length(roles_with_discord_id) == 1
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.role_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = %{}

      result = TestApp.Discord.role_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles invalid permission value" do
      role_struct =
        role(%{
          id: 123_456_789,
          name: "Test Role",
          # Invalid permission value
          permissions: "not_an_integer"
        })

      result = TestApp.Discord.role_from_discord(%{discord_struct: role_struct})

      # This might succeed with normalized permissions or fail with validation error
      # Either is acceptable behavior
      case result do
        {:ok, created_role} ->
          # If it succeeds, permissions should be normalized
          assert is_integer(created_role.permissions)

        {:error, error} ->
          # If it fails, should be a validation error
          error_message = Exception.message(error)
          assert error_message =~ "invalid" or error_message =~ "must be"
      end
    end
  end
end
