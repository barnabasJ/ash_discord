defmodule AshDiscord.Consumer.Handler.GuildRoleTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.GuildRole
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    test "creates role in database" do
      guild_id = generate_snowflake()
      role_data = role()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Role,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}}
      }

      {:ok, role_payload} = Payloads.GuildRole.new(role_data)

      guild_role_create = %Payloads.GuildRoleCreate{
        guild_id: guild_id,
        role: role_payload
      }

      assert :ok =
               GuildRole.create(
                 guild_role_create,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify role was created in database
      roles = TestApp.Discord.GuildRole.read!()
      assert length(roles) == 1

      created_role = hd(roles)
      assert created_role.discord_id == role_data.id
      assert created_role.name == role_data.name
      assert created_role.guild_id == guild_id
    end
  end

  describe "update/3" do
    test "updates existing role in database" do
      guild_id = generate_snowflake()
      old_role = role(%{name: "Old Role"})
      new_role = role(%{id: old_role.id, name: "New Role"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Role,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}}
      }

      {:ok, old_role_payload} = Payloads.GuildRole.new(old_role)
      {:ok, new_role_payload} = Payloads.GuildRole.new(new_role)

      guild_role_update = %Payloads.GuildRoleUpdate{
        guild_id: guild_id,
        old_role: old_role_payload,
        new_role: new_role_payload
      }

      assert :ok =
               GuildRole.update(
                 guild_role_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify role was updated (upserted) in database
      roles = TestApp.Discord.GuildRole.read!()
      assert length(roles) == 1

      updated_role = hd(roles)
      assert updated_role.discord_id == new_role.id
      assert updated_role.name == "New Role"
      assert updated_role.guild_id == guild_id
    end
  end

  describe "delete/3" do
    test "deletes role from database" do
      guild_id = generate_snowflake()
      role_data = role()

      # First create the role
      {:ok, role_payload} = Payloads.GuildRole.new(role_data)

      {:ok, _created} =
        TestApp.Discord.Role
        |> Ash.Changeset.for_create(:from_discord, %{
          data: role_payload,
          identity: %{role_id: role_data.id, guild_id: guild_id}
        })
        |> Ash.create()

      # Verify role exists
      roles_before = TestApp.Discord.GuildRole.read!()
      assert length(roles_before) == 1

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Role,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}}
      }

      guild_role_delete = %Payloads.GuildRoleDelete{
        guild_id: guild_id,
        role: role_payload
      }

      assert :ok =
               GuildRole.delete(
                 guild_role_delete,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify role was deleted from database
      roles_after = TestApp.Discord.GuildRole.read!()
      assert length(roles_after) == 0
    end

    test "handles missing role gracefully" do
      guild_id = generate_snowflake()
      role_data = role()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Role,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}}
      }

      {:ok, role_payload} = Payloads.GuildRole.new(role_data)

      guild_role_delete = %Payloads.GuildRoleDelete{
        guild_id: guild_id,
        role: role_payload
      }

      # Should not crash when role doesn't exist
      assert :ok =
               GuildRole.delete(
                 guild_role_delete,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end
end
