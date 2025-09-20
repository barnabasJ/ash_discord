defmodule AshDiscord.Changes.FromDiscordTest do
  use ExUnit.Case, async: true

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Changes.FromDiscord

  describe "init/1" do
    test "accepts valid Discord entity types" do
      valid_types = [
        :user,
        :guild,
        :guild_member,
        :role,
        :channel,
        :message,
        :emoji,
        :voice_state,
        :webhook,
        :invite,
        :message_attachment,
        :message_reaction,
        :typing_indicator,
        :sticker,
        :interaction
      ]

      for type <- valid_types do
        assert {:ok, [type: ^type]} = FromDiscord.init(type: type)
      end
    end

    test "rejects invalid Discord entity types" do
      invalid_types = [:invalid_type, :not_supported, :random]

      for type <- invalid_types do
        assert_raise ArgumentError, ~r/Invalid Discord entity type/, fn ->
          FromDiscord.init(type: type)
        end
      end
    end

    test "requires type option" do
      assert_raise KeyError, fn ->
        FromDiscord.init([])
      end
    end
  end

  describe "integration with test app resources" do
    test "handles User entity creation" do
      user_struct = user(%{id: 123_456_789, username: "testuser"})

      result = TestApp.Discord.user_from_discord(%{discord_struct: user_struct})

      # For now, just verify it creates successfully
      # Implementation will be added in subsequent tasks
      assert {:ok, _user} = result
    end

    test "handles Guild entity creation" do
      guild_struct = guild(%{id: 987_654_321, name: "Test Guild"})

      result = TestApp.Discord.guild_from_discord(%{discord_struct: guild_struct})

      assert {:ok, _guild} = result
    end

    test "handles GuildMember entity creation" do
      member_struct = member(%{user_id: 222})

      result =
        TestApp.Discord.guild_member_from_discord(%{discord_struct: member_struct, guild_id: 111})

      assert {:ok, _member} = result
    end

    test "handles Role entity creation" do
      role_struct = role(%{id: 456_789_123, name: "Test Role"})

      result = TestApp.Discord.role_from_discord(%{discord_struct: role_struct})

      assert {:ok, _role} = result
    end

    test "handles Emoji entity creation" do
      emoji_struct = emoji(%{id: 789_123_456, name: "test_emoji"})

      result = TestApp.Discord.emoji_from_discord(%{discord_struct: emoji_struct})

      assert {:ok, _emoji} = result
    end

    test "handles API fetch error when no discord_struct provided" do
      result = TestApp.Discord.user_from_discord(%{})

      # Should return error since API fetching returns placeholder error
      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord struct provided"
    end

    test "handles invalid discord_struct format" do
      result = TestApp.Discord.user_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
      assert error_message =~ "is invalid"
    end
  end
end
