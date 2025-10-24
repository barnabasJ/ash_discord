defmodule AshDiscord.Consumer.Handler.GuildBanTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.GuildBan
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "add/3" do
    @tag :fixed
    test "creates ban record in database" do
      guild_id = generate_snowflake()
      user_data = user()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      user_payload = Payloads.User.new!(user_data)

      guild_ban_add = %Payloads.GuildBanAddEvent{
        guild_id: guild_id,
        user: user_payload
      }

      assert :ok =
               GuildBan.add(
                 guild_ban_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [created_ban] = TestApp.Discord.GuildBan.read!(authorize?: false)

      assert created_ban.discord_id == user_data.id
      assert created_ban.guild_id == guild_id
      assert created_ban.user_id == user_data.id
    end

    @tag :fixed
    test "upserts ban record if already exists" do
      guild_id = generate_snowflake()
      user_data = user()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      user_payload = Payloads.User.new!(user_data)

      guild_ban_add = %Payloads.GuildBanAddEvent{
        guild_id: guild_id,
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
      guild_id = generate_snowflake()
      user_data = user()

      user_payload = Payloads.User.new!(user_data)

      TestApp.Discord.guild_ban_from_discord!(
        %{data: %{guild_id: guild_id, user: user_payload}},
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
        guild_id: guild_id,
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
      guild_id = generate_snowflake()
      user_data = user()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}, shared: %{private: %{ash_discord?: true}}}
      }

      user_payload = Payloads.User.new!(user_data)

      guild_ban_remove = %Payloads.GuildBanRemoveEvent{
        guild_id: guild_id,
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
      guild_id_1 = generate_snowflake()
      guild_id_2 = generate_snowflake()
      user_data = user()

      user_payload = Payloads.User.new!(user_data)

      TestApp.Discord.guild_ban_from_discord!(
        %{data: %{guild_id: guild_id_1, user: user_payload}},
        authorize?: false
      )

      TestApp.Discord.guild_ban_from_discord!(
        %{data: %{guild_id: guild_id_2, user: user_payload}},
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
        guild_id: guild_id_1,
        user: user_payload
      }

      assert :ok =
               GuildBan.remove(
                 guild_ban_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )

      [remaining_ban] = TestApp.Discord.GuildBan.read!(authorize?: false)
      assert remaining_ban.guild_id == guild_id_2
    end
  end
end
