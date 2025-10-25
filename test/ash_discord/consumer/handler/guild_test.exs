defmodule AshDiscord.Consumer.Handler.GuildTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators
  use Mimic

  alias AshDiscord.Consumer.Handler.Guild
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "create/3" do
    @tag :fixed
    test "creates guild from Discord event" do
      expect(Nostrum.Api.ApplicationCommand, :bulk_overwrite_guild_commands, fn _guild_id,
                                                                                _commands ->
        {:ok, []}
      end)

      guild_data = guild()
      typed_guild = Payloads.Guild.new!(guild_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      assert {:ok, created_guild} = Guild.create(typed_guild, %Nostrum.Struct.WSState{}, context)

      assert [db_guild] = TestApp.Discord.Guild.read!(authorize?: false)

      assert created_guild.discord_id == guild_data.id
      assert created_guild.name == guild_data.name
      assert db_guild.discord_id == guild_data.id
      assert db_guild.name == guild_data.name
    end

    @tag :fixed
    test "registers guild commands on create" do
      guild_data = guild()
      typed_guild = Payloads.Guild.new!(guild_data)

      expect(Nostrum.Api.ApplicationCommand, :bulk_overwrite_guild_commands, fn guild_id,
                                                                                commands ->
        assert guild_id == guild_data.id
        assert is_list(commands)
        {:ok, []}
      end)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      assert {:ok, _created} = Guild.create(typed_guild, %Nostrum.Struct.WSState{}, context)
    end
  end

  describe "update/3" do
    @tag :fixed
    test "updates existing guild" do
      old_guild = guild(%{name: "Old Name"})
      new_guild = guild(%{id: old_guild.id, name: "New Name"})

      guild_update = Payloads.GuildUpdate.new!({old_guild, new_guild})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      assert :ok = Guild.update(guild_update, %Nostrum.Struct.WSState{}, context)

      assert [updated] = TestApp.Discord.Guild.read!(authorize?: false)

      assert updated.discord_id == new_guild.id
      assert updated.name == "New Name"
    end
  end

  describe "delete/3" do
    @tag :fixed
    test "deletes guild when unavailable is false" do
      guild_data = guild()

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)

      assert [_guild] = TestApp.Discord.Guild.read!(authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      guild_delete = Payloads.GuildDelete.new!({guild_data, false})

      Guild.delete(guild_delete, %Nostrum.Struct.WSState{}, context)

      assert [] = TestApp.Discord.Guild.read!(authorize?: false)
    end

    @tag :fixed
    test "does not delete guild when unavailable is true" do
      guild_data = guild()

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)

      assert [_guild] = TestApp.Discord.Guild.read!(authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      guild_delete = Payloads.GuildDelete.new!({guild_data, true})

      assert :ok = Guild.delete(guild_delete, %Nostrum.Struct.WSState{}, context)

      assert [_guild] = TestApp.Discord.Guild.read!(authorize?: false)
    end
  end

  describe "available/3" do
    @tag :fixed
    test "creates guild when it becomes available" do
      expect(Nostrum.Api.ApplicationCommand, :bulk_overwrite_guild_commands, fn _guild_id,
                                                                                _commands ->
        {:ok, []}
      end)

      guild_data = guild()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      assert {:ok, created} = Guild.available(guild_data, %Nostrum.Struct.WSState{}, context)

      assert [db_guild] = TestApp.Discord.Guild.read!(authorize?: false)
      assert created.discord_id == guild_data.id
      assert db_guild.discord_id == guild_data.id
    end
  end

  describe "unavailable/3" do
    @tag :fixed
    test "returns :ok without error" do
      unavailable_data = unavailable_guild()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      assert :ok = Guild.unavailable(unavailable_data, %Nostrum.Struct.WSState{}, context)
    end
  end
end
