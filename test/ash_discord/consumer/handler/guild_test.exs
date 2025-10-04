defmodule AshDiscord.Consumer.Handler.GuildTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord
  import Mimic

  alias AshDiscord.Consumer.Handler.Guild
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  setup do
    copy(Nostrum.Api.ApplicationCommand)

    stub(Nostrum.Api.ApplicationCommand, :bulk_overwrite_guild_commands, fn _guild_id,
                                                                            _commands ->
      {:ok, []}
    end)

    :ok
  end

  describe "create/3" do
    test "creates guild from Discord event" do
      guild_data = guild()
      # Transform to TypedStruct
      {:ok, typed_guild} = Payloads.Guild.new(guild_data)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      assert {:ok, created_guild} = Guild.create(typed_guild, %Nostrum.Struct.WSState{}, context)

      guilds = TestApp.Discord.Guild.read!()
      assert length(guilds) == 1

      assert created_guild.discord_id == guild_data.id
      assert created_guild.name == guild_data.name
    end

    test "registers guild commands on create" do
      guild_data = guild()
      # Transform to TypedStruct
      {:ok, typed_guild} = Payloads.Guild.new(guild_data)

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
    test "updates existing guild" do
      old_guild = guild(%{name: "Old Name"})
      new_guild = guild(%{id: old_guild.id, name: "New Name"})

      # Transform to TypedStruct GuildUpdate payload
      {:ok, guild_update} = Payloads.GuildUpdate.new({old_guild, new_guild})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      assert :ok = Guild.update(guild_update, %Nostrum.Struct.WSState{}, context)

      guilds = TestApp.Discord.Guild.read!()
      assert length(guilds) == 1

      updated = hd(guilds)
      assert updated.discord_id == new_guild.id
      assert updated.name == "New Name"
    end
  end

  describe "delete/3" do
    test "deletes guild when unavailable is false" do
      guild_data = guild()

      # First create the guild - pass Nostrum struct directly
      {:ok, _created} =
        TestApp.Discord.Guild
        |> Ash.Changeset.for_create(:from_discord, %{
          data: guild_data
        })
        |> Ash.create()

      guilds_before = TestApp.Discord.Guild.read!()
      assert length(guilds_before) == 1

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      # Transform to TypedStruct GuildDelete payload
      {:ok, guild_delete} = Payloads.GuildDelete.new({guild_data, false})

      Guild.delete(guild_delete, %Nostrum.Struct.WSState{}, context)

      guilds_after = TestApp.Discord.Guild.read!()
      assert length(guilds_after) == 0
    end

    test "does not delete guild when unavailable is true" do
      guild_data = guild()

      {:ok, _created} =
        TestApp.Discord.Guild
        |> Ash.Changeset.for_create(:from_discord, %{
          data: guild_data
        })
        |> Ash.create()

      guilds_before = TestApp.Discord.Guild.read!()
      assert length(guilds_before) == 1

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      # Transform to TypedStruct GuildDelete payload
      {:ok, guild_delete} = Payloads.GuildDelete.new({guild_data, true})

      assert :ok = Guild.delete(guild_delete, %Nostrum.Struct.WSState{}, context)

      guilds_after = TestApp.Discord.Guild.read!()
      assert length(guilds_after) == 1
    end
  end

  describe "available/3" do
    test "creates guild when it becomes available" do
      guild_data = guild()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.Guild,
        guild: nil,
        user: nil
      }

      assert {:ok, created} = Guild.available(guild_data, %Nostrum.Struct.WSState{}, context)

      guilds = TestApp.Discord.Guild.read!()
      assert length(guilds) == 1
      assert created.discord_id == guild_data.id
    end
  end

  describe "unavailable/3" do
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
