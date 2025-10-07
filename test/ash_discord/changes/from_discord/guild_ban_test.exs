defmodule AshDiscord.Changes.FromDiscord.GuildBanTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Payloads

  describe "change/2" do
    test "transforms guild ban data correctly" do
      guild_id = generate_snowflake()
      user_data = user()
      {:ok, user_payload} = Payloads.User.new(user_data)

      {:ok, ban} =
        TestApp.Discord.GuildBan
        |> Ash.Changeset.for_create(:from_discord, %{
          data: %{guild_id: guild_id, user: user_payload}
        })
        |> Ash.create()

      assert ban.discord_id == user_data.id
      assert ban.guild_id == guild_id
      assert ban.user_id == user_data.id
    end

    test "upserts on discord_id and guild_id identity" do
      guild_id = generate_snowflake()
      user_data = user()
      {:ok, user_payload} = Payloads.User.new(user_data)

      # Create ban first time
      {:ok, ban1} =
        TestApp.Discord.GuildBan
        |> Ash.Changeset.for_create(:from_discord, %{
          data: %{guild_id: guild_id, user: user_payload}
        })
        |> Ash.create()

      # Create again with same discord_id and guild_id (should upsert)
      {:ok, ban2} =
        TestApp.Discord.GuildBan
        |> Ash.Changeset.for_create(:from_discord, %{
          data: %{guild_id: guild_id, user: user_payload}
        })
        |> Ash.create()

      # Should be same record
      assert ban1.id == ban2.id

      # Verify only one ban exists
      bans = TestApp.Discord.GuildBan.read!()
      assert length(bans) == 1
    end

    test "allows same user banned in different guilds" do
      guild_id_1 = generate_snowflake()
      guild_id_2 = generate_snowflake()
      user_data = user()
      {:ok, user_payload} = Payloads.User.new(user_data)

      # Ban in guild 1
      {:ok, ban1} =
        TestApp.Discord.GuildBan
        |> Ash.Changeset.for_create(:from_discord, %{
          data: %{guild_id: guild_id_1, user: user_payload}
        })
        |> Ash.create()

      # Ban same user in guild 2
      {:ok, ban2} =
        TestApp.Discord.GuildBan
        |> Ash.Changeset.for_create(:from_discord, %{
          data: %{guild_id: guild_id_2, user: user_payload}
        })
        |> Ash.create()

      # Should be different records
      assert ban1.id != ban2.id

      # Verify two bans exist
      bans = TestApp.Discord.GuildBan.read!()
      assert length(bans) == 2

      assert Enum.all?(bans, fn ban -> ban.discord_id == user_data.id end)
      assert Enum.map(bans, & &1.guild_id) |> Enum.sort() == Enum.sort([guild_id_1, guild_id_2])
    end

    test "returns error when data argument is missing" do
      result =
        TestApp.Discord.GuildBan
        |> Ash.Changeset.for_create(:from_discord, %{})
        |> Ash.create()

      assert {:error, %Ash.Error.Invalid{}} = result
    end
  end
end
