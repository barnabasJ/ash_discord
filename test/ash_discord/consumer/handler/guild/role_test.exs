defmodule AshDiscord.Consumer.Handler.Guild.RoleTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Consumer.Handler.Guild.Role
  alias TestApp.TestConsumer

  describe "create/4" do
    test "creates role in database" do
      guild_id = generate_snowflake()
      role_data = role()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Role.create(
                 TestConsumer,
                 {guild_id, role_data},
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify role was created in database
      roles = TestApp.Discord.Role.read!()
      assert length(roles) == 1

      created_role = hd(roles)
      assert created_role.discord_id == role_data.id
      assert created_role.name == role_data.name
      assert created_role.guild_id == guild_id
    end
  end

  describe "update/4" do
    test "updates existing role in database" do
      guild_id = generate_snowflake()
      old_role = role(%{name: "Old Role"})
      new_role = role(%{id: old_role.id, name: "New Role"})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      assert :ok =
               Role.update(
                 TestConsumer,
                 {guild_id, old_role, new_role},
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify role was updated (upserted) in database
      roles = TestApp.Discord.Role.read!()
      assert length(roles) == 1

      updated_role = hd(roles)
      assert updated_role.discord_id == new_role.id
      assert updated_role.name == "New Role"
      assert updated_role.guild_id == guild_id
    end
  end

  describe "delete/4" do
    test "returns :ok - delete not yet implemented" do
      guild_id = generate_snowflake()
      role_data = role()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      # Delete is TODO - currently returns :ok without side effects
      assert :ok =
               Role.delete(
                 TestConsumer,
                 {guild_id, role_data},
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end
end
