defmodule AshDiscord.Consumer.Handler.GuildBanTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.GuildBan
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "add/3" do
    @tag :fixed
    test "creates ban record in database" do
      guild = guild()
      user_data = user()

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      user_payload = Payloads.User.new!(user_data)

      guild_ban_add = %Payloads.GuildBanAddEvent{
        guild_id: guild.id,
        user: user_payload
      }

      assert :ok =
               GuildBan.add(
                 guild_ban_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [created_ban] = TestApp.Discord.GuildBan.read!(authorize?: false)

      assert created_ban.guild_discord_id == guild.id
      assert created_ban.user_discord_id == user_data.id

      loaded_ban =
        created_ban
        |> Ash.load!(:guild, authorize?: false)
        |> Ash.load!(:user, authorize?: false)

      assert loaded_ban.guild.discord_id == guild.id
      assert loaded_ban.user.discord_id == user_data.id
    end

    @tag :fixed
    test "upserts ban record if already exists" do
      guild = guild()
      user_data = user()

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      user_payload = Payloads.User.new!(user_data)

      guild_ban_add = %Payloads.GuildBanAddEvent{
        guild_id: guild.id,
        user: user_payload
      }

      assert :ok =
               GuildBan.add(
                 guild_ban_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      assert :ok =
               GuildBan.add(
                 guild_ban_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [_ban] = TestApp.Discord.GuildBan.read!(authorize?: false)
    end
  end

  describe "remove/3" do
    @tag :fixed
    test "deletes ban from database" do
      guild = guild()
      user_data = user()

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      user_payload = Payloads.User.new!(user_data)

      TestApp.Discord.guild_ban_from_discord!(
        %{data: %{guild_id: guild.id, user: user_payload}},
        authorize?: false
      )

      [_ban] = TestApp.Discord.GuildBan.read!(authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      guild_ban_remove = %Payloads.GuildBanRemoveEvent{
        guild_id: guild.id,
        user: user_payload
      }

      assert :ok =
               GuildBan.remove(
                 guild_ban_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [] = TestApp.Discord.GuildBan.read!(authorize?: false)
    end

    @tag :fixed
    test "handles missing ban gracefully" do
      guild = guild()
      user_data = user()

      TestApp.Discord.guild_from_discord!(%{data: guild}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      user_payload = Payloads.User.new!(user_data)

      guild_ban_remove = %Payloads.GuildBanRemoveEvent{
        guild_id: guild.id,
        user: user_payload
      }

      assert :ok =
               GuildBan.remove(
                 guild_ban_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end

    @tag :fixed
    test "only deletes ban for specific guild" do
      guild_1 = guild()
      guild_2 = guild()
      user_data = user()

      TestApp.Discord.guild_from_discord!(%{data: guild_1}, authorize?: false)
      TestApp.Discord.guild_from_discord!(%{data: guild_2}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      user_payload = Payloads.User.new!(user_data)

      TestApp.Discord.guild_ban_from_discord!(
        %{data: %{guild_id: guild_1.id, user: user_payload}},
        authorize?: false
      )

      TestApp.Discord.guild_ban_from_discord!(
        %{data: %{guild_id: guild_2.id, user: user_payload}},
        authorize?: false
      )

      [_ban1, _ban2] = TestApp.Discord.GuildBan.read!(authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      guild_ban_remove = %Payloads.GuildBanRemoveEvent{
        guild_id: guild_1.id,
        user: user_payload
      }

      assert :ok =
               GuildBan.remove(
                 guild_ban_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [remaining_ban] = TestApp.Discord.GuildBan.read!(authorize?: false)
      assert remaining_ban.guild_discord_id == guild_2.id
    end
  end
end
