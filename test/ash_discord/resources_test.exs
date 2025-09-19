defmodule AshDiscord.ResourcesTest do
  use TestApp.DataCase

  describe "Guild resource" do
    test "create guild with from_discord action" do
      guild_data = %{
        discord_id: 123_456_789_012_345_678,
        name: "Test Guild",
        description: "A test guild"
      }

      assert {:ok, guild} = TestApp.Discord.from_discord_guild(guild_data)
      assert guild.discord_id == guild_data.discord_id
      assert guild.name == guild_data.name
      assert guild.description == guild_data.description
    end

    test "upsert guild updates existing record" do
      guild_data = %{
        discord_id: 123_456_789_012_345_678,
        name: "Test Guild",
        description: "Original description"
      }

      # Create initial guild
      assert {:ok, guild1} =
               TestApp.Discord.create(TestApp.Discord.Guild, :from_discord, guild_data)

      # Update with same discord_id but different name
      updated_data = Map.put(guild_data, :name, "Updated Guild Name")

      assert {:ok, guild2} =
               TestApp.Discord.create(TestApp.Discord.Guild, :from_discord, updated_data)

      # Should be same record with updated name
      assert guild1.id == guild2.id
      assert guild2.name == "Updated Guild Name"
      assert guild2.discord_id == guild_data.discord_id
    end

    test "discord_struct helper formats data correctly" do
      attrs = %{
        discord_id: 123_456_789,
        name: "Test Guild",
        description: "Test description"
      }

      struct = TestApp.Discord.Guild.discord_struct(attrs)

      assert struct.id == attrs.discord_id
      assert struct.name == attrs.name
      assert struct.description == attrs.description
    end
  end

  describe "User resource" do
    test "create user with from_discord action" do
      user_data = %{
        discord_id: 987_654_321_098_765_432,
        username: "testuser",
        discriminator: "1234",
        avatar: "avatar_hash"
      }

      assert {:ok, user} = TestApp.Discord.create(TestApp.Discord.User, :from_discord, user_data)
      assert user.discord_id == user_data.discord_id
      assert user.username == user_data.username
      assert user.discriminator == user_data.discriminator
      assert user.avatar == user_data.avatar
    end

    test "upsert user updates existing record" do
      user_data = %{
        discord_id: 987_654_321_098_765_432,
        username: "testuser",
        discriminator: "1234"
      }

      # Create initial user
      assert {:ok, user1} = TestApp.Discord.create(TestApp.Discord.User, :from_discord, user_data)

      # Update with same discord_id but different username
      updated_data = Map.put(user_data, :username, "updated_username")

      assert {:ok, user2} =
               TestApp.Discord.create(TestApp.Discord.User, :from_discord, updated_data)

      # Should be same record with updated username
      assert user1.id == user2.id
      assert user2.username == "updated_username"
      assert user2.discord_id == user_data.discord_id
    end

    test "discord_struct helper formats data correctly" do
      attrs = %{
        discord_id: 123_456_789,
        username: "testuser",
        discriminator: "1234",
        avatar: "avatar_hash",
        bot: false,
        display_name: "Test User"
      }

      struct = TestApp.Discord.User.discord_struct(attrs)

      assert struct.id == attrs.discord_id
      assert struct.username == attrs.username
      assert struct.discriminator == attrs.discriminator
      assert struct.avatar == attrs.avatar
      assert struct.bot == attrs.bot
      assert struct.global_name == attrs.display_name
    end
  end

  describe "Message resource" do
    test "create message with from_discord action creates relationships" do
      # First create the dependent records
      guild_data = %{
        discord_id: 111_222_333_444_555_666,
        name: "Test Guild"
      }

      assert {:ok, _guild} =
               TestApp.Discord.create(TestApp.Discord.Guild, :from_discord, guild_data)

      user_data = %{
        discord_id: 777_888_999_000_111_222,
        username: "author_user"
      }

      assert {:ok, _user} = TestApp.Discord.create(TestApp.Discord.User, :from_discord, user_data)

      message_data = %{
        discord_id: 555_666_777_888_999_000,
        content: "Test message content",
        channel_id: 987_654_321_098_765_432,
        guild_id: 111_222_333_444_555_666,
        author_id: 777_888_999_000_111_222,
        timestamp: DateTime.utc_now()
      }

      assert {:ok, message} =
               TestApp.Discord.create(TestApp.Discord.Message, :from_discord, message_data)

      assert message.discord_id == message_data.discord_id
      assert message.content == message_data.content
      assert message.channel_id == message_data.channel_id
      assert message.guild_id == message_data.guild_id
      assert message.author_id == message_data.author_id
    end

    test "message upsert updates content and edited_timestamp" do
      # Setup dependencies
      guild_data = %{discord_id: 111_222_333_444_555_666, name: "Test Guild"}
      user_data = %{discord_id: 777_888_999_000_111_222, username: "author_user"}

      assert {:ok, _guild} =
               TestApp.Discord.create(TestApp.Discord.Guild, :from_discord, guild_data)

      assert {:ok, _user} = TestApp.Discord.create(TestApp.Discord.User, :from_discord, user_data)

      message_data = %{
        discord_id: 555_666_777_888_999_000,
        content: "Original content",
        channel_id: 987_654_321_098_765_432,
        guild_id: 111_222_333_444_555_666,
        author_id: 777_888_999_000_111_222,
        timestamp: DateTime.utc_now(),
        edited_timestamp: nil
      }

      # Create initial message
      assert {:ok, message1} =
               TestApp.Discord.create(TestApp.Discord.Message, :from_discord, message_data)

      # Update with same discord_id but different content
      updated_data = %{
        message_data
        | content: "Updated content",
          edited_timestamp: DateTime.utc_now()
      }

      assert {:ok, message2} =
               TestApp.Discord.create(TestApp.Discord.Message, :from_discord, updated_data)

      # Should be same record with updated content
      assert message1.id == message2.id
      assert message2.content == "Updated content"
      assert message2.edited_timestamp != nil
    end

    test "discord_struct helper formats data correctly" do
      timestamp = DateTime.utc_now()
      edited_timestamp = DateTime.utc_now()

      attrs = %{
        discord_id: 123_456_789,
        content: "Test message",
        channel_id: 987_654_321,
        guild_id: 111_222_333,
        author_id: 444_555_666,
        timestamp: timestamp,
        edited_timestamp: edited_timestamp
      }

      struct = TestApp.Discord.Message.discord_struct(attrs)

      assert struct.id == attrs.discord_id
      assert struct.content == attrs.content
      assert struct.channel_id == attrs.channel_id
      assert struct.guild_id == attrs.guild_id
      assert struct.author == %{id: attrs.author_id}
      assert struct.timestamp == timestamp
      assert struct.edited_timestamp == edited_timestamp
    end
  end

  describe "GuildMember resource" do
    test "create guild member with from_discord action creates relationships" do
      # Setup dependencies
      guild_data = %{discord_id: 111_222_333_444_555_666, name: "Test Guild"}
      user_data = %{discord_id: 777_888_999_000_111_222, username: "member_user"}

      assert {:ok, _guild} =
               TestApp.Discord.create(TestApp.Discord.Guild, :from_discord, guild_data)

      assert {:ok, _user} = TestApp.Discord.create(TestApp.Discord.User, :from_discord, user_data)

      member_data = %{
        user_id: 777_888_999_000_111_222,
        guild_id: 111_222_333_444_555_666,
        nick: "Member Nickname",
        roles: [123_456_789, 987_654_321],
        joined_at: DateTime.utc_now()
      }

      assert {:ok, member} =
               TestApp.Discord.create(TestApp.Discord.GuildMember, :from_discord, member_data)

      assert member.user_id == member_data.user_id
      assert member.guild_id == member_data.guild_id
      assert member.nick == member_data.nick
      assert member.roles == member_data.roles
    end

    test "guild member upsert updates nick and roles" do
      # Setup dependencies
      guild_data = %{discord_id: 111_222_333_444_555_666, name: "Test Guild"}
      user_data = %{discord_id: 777_888_999_000_111_222, username: "member_user"}

      assert {:ok, _guild} =
               TestApp.Discord.create(TestApp.Discord.Guild, :from_discord, guild_data)

      assert {:ok, _user} = TestApp.Discord.create(TestApp.Discord.User, :from_discord, user_data)

      member_data = %{
        user_id: 777_888_999_000_111_222,
        guild_id: 111_222_333_444_555_666,
        nick: "Original Nick",
        roles: [123_456_789],
        joined_at: DateTime.utc_now()
      }

      # Create initial member
      assert {:ok, member1} =
               TestApp.Discord.create(TestApp.Discord.GuildMember, :from_discord, member_data)

      # Update with same user_id/guild_id but different nick and roles
      updated_data = %{member_data | nick: "Updated Nick", roles: [123_456_789, 987_654_321]}

      assert {:ok, member2} =
               TestApp.Discord.create(TestApp.Discord.GuildMember, :from_discord, updated_data)

      # Should be same record with updated fields
      assert member1.id == member2.id
      assert member2.nick == "Updated Nick"
      assert member2.roles == [123_456_789, 987_654_321]
    end

    test "discord_struct helper formats data correctly" do
      joined_at = DateTime.utc_now()

      attrs = %{
        user_id: 777_888_999,
        guild_id: 111_222_333,
        nick: "Test Nick",
        roles: [123_456, 789_012],
        joined_at: joined_at
      }

      struct = TestApp.Discord.GuildMember.discord_struct(attrs)

      assert struct.user == %{id: attrs.user_id}
      assert struct.guild_id == attrs.guild_id
      assert struct.nick == attrs.nick
      assert struct.roles == attrs.roles
      assert struct.joined_at == joined_at
    end
  end
end
