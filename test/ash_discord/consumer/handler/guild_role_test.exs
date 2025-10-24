defmodule AshDiscord.Consumer.Handler.GuildRoleTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.GuildRole
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    @tag :fixed
    test "creates role in database" do
      guild = guild()
      role_data = role()

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Role,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}}
      }

      role_payload = Payloads.Role.new!(role_data)

      guild_role_create = %Payloads.GuildRoleCreate{
        guild_id: guild.id,
        role: role_payload
      }

      assert :ok =
               GuildRole.create(
                 guild_role_create,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [created_role] = TestApp.Discord.Role.read!(authorize?: false)

      assert created_role.discord_id == role_data.id
      assert created_role.name == role_data.name
      assert created_role.guild_discord_id == guild.id
    end
  end

  describe "update/3" do
    @tag :fixed
    test "updates existing role in database" do
      guild = guild()
      old_role = role(%{name: "Old Role"})
      new_role = role(%{id: old_role.id, name: "New Role"})

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Role,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}}
      }

      old_role_payload = Payloads.Role.new!(old_role)
      new_role_payload = Payloads.Role.new!(new_role)

      guild_role_update = %Payloads.GuildRoleUpdate{
        guild_id: guild.id,
        old_role: old_role_payload,
        new_role: new_role_payload
      }

      assert :ok =
               GuildRole.update(
                 guild_role_update,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [updated_role] = TestApp.Discord.Role.read!(authorize?: false)

      assert updated_role.discord_id == new_role.id
      assert updated_role.name == "New Role"
      assert updated_role.guild_discord_id == guild.id
    end
  end

  describe "delete/3" do
    @tag :fixed
    test "deletes role from database" do
      guild = guild()
      role_data = role()

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      role_payload = Payloads.Role.new!(role_data)

      TestApp.Discord.role_from_discord!(
        %{
          data: role_payload,
          identity: %{role_id: role_data.id, guild_id: guild.id}
        },
        authorize?: false
      )

      [_created] = TestApp.Discord.Role.read!(authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Role,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}}
      }

      guild_role_delete = %Payloads.GuildRoleDelete{
        guild_id: guild.id,
        role: role_payload
      }

      assert :ok =
               GuildRole.delete(
                 guild_role_delete,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [] = TestApp.Discord.Role.read!(authorize?: false)
    end

    @tag :fixed
    test "handles missing role gracefully" do
      guild = guild()
      role_data = role()

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Role,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}}
      }

      role_payload = Payloads.Role.new!(role_data)

      guild_role_delete = %Payloads.GuildRoleDelete{
        guild_id: guild.id,
        role: role_payload
      }

      assert :ok =
               GuildRole.delete(
                 guild_role_delete,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end
  end
end
