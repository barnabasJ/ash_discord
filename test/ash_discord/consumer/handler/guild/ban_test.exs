defmodule AshDiscord.Consumer.Handler.Guild.BanTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Consumer.Handler.Guild.Ban
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "add/3" do
    test "creates ban record in database" do
      guild_id = generate_snowflake()
      user_data = user()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil
      }

      {:ok, user_payload} = Payloads.User.new(user_data)

      guild_ban_add = %Payloads.GuildBanAddEvent{
        guild_id: guild_id,
        user: user_payload
      }

      assert :ok =
               Ban.add(
                 guild_ban_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify ban was created in database
      bans = TestApp.Discord.GuildBan.read!()
      assert length(bans) == 1

      created_ban = hd(bans)
      assert created_ban.discord_id == user_data.id
      assert created_ban.guild_id == guild_id
      assert created_ban.user_id == user_data.id
    end

    test "upserts ban record if already exists" do
      guild_id = generate_snowflake()
      user_data = user()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil
      }

      {:ok, user_payload} = Payloads.User.new(user_data)

      guild_ban_add = %Payloads.GuildBanAddEvent{
        guild_id: guild_id,
        user: user_payload
      }

      # Create ban first time
      assert :ok =
               Ban.add(
                 guild_ban_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Create again (should upsert)
      assert :ok =
               Ban.add(
                 guild_ban_add,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify only one ban exists
      bans = TestApp.Discord.GuildBan.read!()
      assert length(bans) == 1
    end
  end

  describe "remove/3" do
    test "deletes ban from database" do
      guild_id = generate_snowflake()
      user_data = user()

      # First create the ban
      {:ok, user_payload} = Payloads.User.new(user_data)

      {:ok, _created} =
        TestApp.Discord.GuildBan
        |> Ash.Changeset.for_create(:from_discord, %{
          data: %{guild_id: guild_id, user: user_payload}
        })
        |> Ash.create()

      # Verify ban exists
      bans_before = TestApp.Discord.GuildBan.read!()
      assert length(bans_before) == 1

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil
      }

      guild_ban_remove = %Payloads.GuildBanRemoveEvent{
        guild_id: guild_id,
        user: user_payload
      }

      assert :ok =
               Ban.remove(
                 guild_ban_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify ban was deleted from database
      bans_after = TestApp.Discord.GuildBan.read!()
      assert length(bans_after) == 0
    end

    test "handles missing ban gracefully" do
      guild_id = generate_snowflake()
      user_data = user()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil
      }

      {:ok, user_payload} = Payloads.User.new(user_data)

      guild_ban_remove = %Payloads.GuildBanRemoveEvent{
        guild_id: guild_id,
        user: user_payload
      }

      # Should not crash when ban doesn't exist
      assert :ok =
               Ban.remove(
                 guild_ban_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )
    end

    test "only deletes ban for specific guild" do
      guild_id_1 = generate_snowflake()
      guild_id_2 = generate_snowflake()
      user_data = user()

      {:ok, user_payload} = Payloads.User.new(user_data)

      # Create ban in guild 1
      {:ok, _ban1} =
        TestApp.Discord.GuildBan
        |> Ash.Changeset.for_create(:from_discord, %{
          data: %{guild_id: guild_id_1, user: user_payload}
        })
        |> Ash.create()

      # Create ban in guild 2 with same user
      {:ok, _ban2} =
        TestApp.Discord.GuildBan
        |> Ash.Changeset.for_create(:from_discord, %{
          data: %{guild_id: guild_id_2, user: user_payload}
        })
        |> Ash.create()

      # Verify 2 bans exist
      bans_before = TestApp.Discord.GuildBan.read!()
      assert length(bans_before) == 2

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.GuildBan,
        guild: nil,
        user: nil
      }

      # Remove ban from guild 1 only
      guild_ban_remove = %Payloads.GuildBanRemoveEvent{
        guild_id: guild_id_1,
        user: user_payload
      }

      assert :ok =
               Ban.remove(
                 guild_ban_remove,
                 %Nostrum.Struct.WSState{},
                 context
               )

      # Verify only guild 2 ban remains
      bans_after = TestApp.Discord.GuildBan.read!()
      assert length(bans_after) == 1
      remaining_ban = hd(bans_after)
      assert remaining_ban.guild_id == guild_id_2
    end
  end
end
