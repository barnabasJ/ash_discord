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
      user_struct =
        user(%{
          id: 123_456_789,
          username: "testuser",
          avatar: "avatar_hash_123",
          discriminator: "1234"
        })

      result = TestApp.Discord.user_from_discord(%{discord_struct: user_struct})

      assert {:ok, created_user} = result

      # Verify Discord data was transformed correctly
      assert created_user.discord_id == user_struct.id
      assert created_user.discord_username == user_struct.username
      assert created_user.discord_avatar == user_struct.avatar
      assert created_user.email == "discord+#{user_struct.id}@discord.local"
    end

    test "handles Guild entity creation" do
      guild_struct =
        guild(%{
          id: 987_654_321,
          name: "Test Guild",
          description: "A test guild for testing",
          icon: "guild_icon_hash"
        })

      result = TestApp.Discord.guild_from_discord(%{discord_struct: guild_struct})

      assert {:ok, created_guild} = result

      # Verify Discord data was transformed correctly
      assert created_guild.discord_id == guild_struct.id
      assert created_guild.name == guild_struct.name
      assert created_guild.description == guild_struct.description
      assert created_guild.icon == guild_struct.icon
    end

    test "handles GuildMember entity creation" do
      member_struct =
        member(%{
          user_id: 222,
          nick: "TestNick",
          roles: [123, 456],
          joined_at: "2023-01-15T10:30:00Z"
        })

      result =
        TestApp.Discord.guild_member_from_discord(%{discord_struct: member_struct, guild_id: 111})

      assert {:ok, created_member} = result

      # Verify Discord data was transformed correctly
      assert created_member.guild_id == 111
      assert created_member.user_id == member_struct.user_id
      assert created_member.nick == member_struct.nick
      assert created_member.roles == member_struct.roles

      # Verify datetime parsing
      assert created_member.joined_at != nil
      assert %DateTime{} = created_member.joined_at
    end

    test "handles Role entity creation" do
      role_struct =
        role(%{
          id: 456_789_123,
          name: "Test Role",
          # Red color
          color: 16_711_680,
          # Permission bitfield
          permissions: 104_324_673,
          hoist: true,
          position: 5,
          managed: false,
          mentionable: true
        })

      result = TestApp.Discord.role_from_discord(%{discord_struct: role_struct})

      assert {:ok, created_role} = result

      # Verify Discord data was transformed correctly
      assert created_role.discord_id == role_struct.id
      assert created_role.name == role_struct.name
      assert created_role.color == role_struct.color
      # Converted to string
      assert created_role.permissions == "#{role_struct.permissions}"
      assert created_role.hoist == role_struct.hoist
      assert created_role.position == role_struct.position
      assert created_role.managed == role_struct.managed
      assert created_role.mentionable == role_struct.mentionable
    end

    test "handles Emoji entity creation" do
      emoji_struct =
        emoji(%{
          id: 789_123_456,
          name: "test_emoji",
          animated: true,
          managed: false,
          require_colons: true
        })

      result = TestApp.Discord.emoji_from_discord(%{discord_struct: emoji_struct})

      assert {:ok, created_emoji} = result

      # Verify Discord data was transformed correctly
      assert created_emoji.discord_id == emoji_struct.id
      assert created_emoji.name == emoji_struct.name
      assert created_emoji.animated == emoji_struct.animated
      assert created_emoji.managed == emoji_struct.managed
      assert created_emoji.require_colons == emoji_struct.require_colons
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

    test "upsert behavior works correctly - updates existing records" do
      user_struct =
        user(%{
          id: 555_666_777,
          username: "original_user",
          avatar: "original_avatar"
        })

      # Create initial user
      {:ok, original_user} = TestApp.Discord.user_from_discord(%{discord_struct: user_struct})

      # Update the same user with new data
      updated_user_struct =
        user(%{
          # Same ID
          id: 555_666_777,
          # New username
          username: "updated_user",
          # New avatar
          avatar: "updated_avatar"
        })

      {:ok, updated_user} =
        TestApp.Discord.user_from_discord(%{discord_struct: updated_user_struct})

      # Should be the same record (same Ash ID), not a new one
      assert updated_user.id == original_user.id
      assert updated_user.discord_id == original_user.discord_id

      # But with updated attributes
      assert updated_user.discord_username == "updated_user"
      assert updated_user.discord_avatar == "updated_avatar"

      # Verify only one user record exists
      all_users = TestApp.Discord.User.read!()
      users_with_discord_id = Enum.filter(all_users, &(&1.discord_id == 555_666_777))
      assert length(users_with_discord_id) == 1
    end

    test "handles nil and empty values gracefully" do
      # Guild with nil description and icon
      guild_struct =
        guild(%{
          id: 888_999_000,
          name: "Minimal Guild",
          description: nil,
          icon: nil
        })

      result = TestApp.Discord.guild_from_discord(%{discord_struct: guild_struct})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == guild_struct.id
      assert created_guild.name == guild_struct.name
      assert created_guild.description == nil
      assert created_guild.icon == nil
    end

    test "handles datetime parsing edge cases" do
      # Member with nil joined_at
      member_struct =
        member(%{
          user_id: 333,
          joined_at: nil
        })

      result =
        TestApp.Discord.guild_member_from_discord(%{discord_struct: member_struct, guild_id: 444})

      assert {:ok, created_member} = result
      assert created_member.guild_id == 444
      assert created_member.user_id == member_struct.user_id
      assert created_member.joined_at == nil
    end
  end
end
