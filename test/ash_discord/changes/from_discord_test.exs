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

    test "handles Channel entity creation with permission overwrites" do
      channel_struct =
        channel(%{
          id: 111_222_333,
          name: "test-channel",
          type: 0,
          position: 1,
          permission_overwrites: [
            %{id: 123, type: 0, allow: 1024, deny: 0},
            %{id: 456, type: 1, allow: 0, deny: 2048}
          ]
        })

      result = TestApp.Discord.channel_from_discord(%{discord_struct: channel_struct})

      assert {:ok, created_channel} = result
      assert created_channel.discord_id == channel_struct.id
      assert created_channel.name == channel_struct.name
      assert created_channel.type == channel_struct.type
      assert created_channel.position == channel_struct.position

      # Verify permission overwrites transformation
      assert length(created_channel.permission_overwrites) == 2
      first_overwrite = hd(created_channel.permission_overwrites)
      assert first_overwrite["id"] == "123"
      assert first_overwrite["type"] == 0
      assert first_overwrite["allow"] == "1024"
      assert first_overwrite["deny"] == "0"
    end

    test "handles VoiceState entity creation with boolean fields" do
      voice_state_struct =
        voice_state(%{
          user_id: 444_555_666,
          channel_id: 777_888_999,
          session_id: "session123",
          deaf: true,
          mute: false,
          self_deaf: true
        })

      result = TestApp.Discord.voice_state_from_discord(%{discord_struct: voice_state_struct})

      assert {:ok, created_voice_state} = result
      assert created_voice_state.user_id == voice_state_struct.user_id
      assert created_voice_state.channel_id == voice_state_struct.channel_id
      assert created_voice_state.session_id == voice_state_struct.session_id
      assert created_voice_state.deaf == true
      assert created_voice_state.mute == false
      assert created_voice_state.self_deaf == true
    end

    test "handles Webhook entity creation" do
      webhook_struct =
        webhook(%{
          id: 666_777_888,
          name: "Test Webhook",
          channel_id: 999_000_111,
          avatar: "webhook_avatar_hash",
          token: "webhook_token_123"
        })

      result = TestApp.Discord.webhook_from_discord(%{discord_struct: webhook_struct})

      assert {:ok, created_webhook} = result
      assert created_webhook.discord_id == webhook_struct.id
      assert created_webhook.name == webhook_struct.name
      assert created_webhook.channel_id == webhook_struct.channel_id
      assert created_webhook.avatar == webhook_struct.avatar
      assert created_webhook.token == webhook_struct.token
    end

    test "handles Invite entity creation with datetime parsing" do
      invite_struct =
        invite(%{
          code: "abc123",
          guild_id: 123_456_789,
          channel_id: 987_654_321,
          uses: 5,
          max_uses: 10,
          expires_at: "2024-12-31T23:59:59Z"
        })

      result = TestApp.Discord.invite_from_discord(%{discord_struct: invite_struct})

      assert {:ok, created_invite} = result
      assert created_invite.code == invite_struct.code
      assert created_invite.guild_id == invite_struct.guild_id
      assert created_invite.channel_id == invite_struct.channel_id
      assert created_invite.uses == invite_struct.uses
      assert created_invite.max_uses == invite_struct.max_uses
      assert %DateTime{} = created_invite.expires_at
    end

    test "handles MessageAttachment entity creation" do
      attachment_struct =
        message_attachment(%{
          id: 111_222_333,
          filename: "image.png",
          size: 1_024_000,
          url: "https://cdn.discord.com/attachments/123/456/image.png",
          height: 800,
          width: 600,
          content_type: "image/png"
        })

      result =
        TestApp.Discord.message_attachment_from_discord(%{discord_struct: attachment_struct})

      assert {:ok, created_attachment} = result
      assert created_attachment.discord_id == attachment_struct.id
      assert created_attachment.filename == attachment_struct.filename
      assert created_attachment.size == attachment_struct.size
      assert created_attachment.url == attachment_struct.url
      assert created_attachment.height == attachment_struct.height
      assert created_attachment.width == attachment_struct.width
      assert created_attachment.content_type == attachment_struct.content_type
    end

    test "handles MessageReaction entity creation" do
      reaction_struct = %{
        emoji_id: 123_456,
        emoji_name: "thumbsup",
        count: 5,
        me: true
      }

      result = TestApp.Discord.message_reaction_from_discord(%{discord_struct: reaction_struct})

      assert {:ok, created_reaction} = result
      assert created_reaction.emoji_id == reaction_struct.emoji_id
      assert created_reaction.emoji_name == reaction_struct.emoji_name
      assert created_reaction.count == reaction_struct.count
      assert created_reaction.me == reaction_struct.me
    end

    test "handles TypingIndicator entity creation" do
      typing_struct = %{
        user_id: 111_222_333,
        channel_id: 444_555_666,
        guild_id: 777_888_999,
        timestamp: "2024-01-01T12:00:00Z"
      }

      result = TestApp.Discord.typing_indicator_from_discord(%{discord_struct: typing_struct})

      assert {:ok, created_typing} = result
      assert created_typing.user_id == typing_struct.user_id
      assert created_typing.channel_id == typing_struct.channel_id
      assert created_typing.guild_id == typing_struct.guild_id
      assert %DateTime{} = created_typing.timestamp
    end

    test "handles Sticker entity creation" do
      sticker_struct = %{
        id: 999_888_777,
        name: "test_sticker",
        description: "A test sticker",
        tags: "funny,meme",
        format_type: 1,
        guild_id: 666_555_444
      }

      result = TestApp.Discord.sticker_from_discord(%{discord_struct: sticker_struct})

      assert {:ok, created_sticker} = result
      assert created_sticker.discord_id == sticker_struct.id
      assert created_sticker.name == sticker_struct.name
      assert created_sticker.description == sticker_struct.description
      assert created_sticker.tags == sticker_struct.tags
      assert created_sticker.format_type == sticker_struct.format_type
      assert created_sticker.guild_id == sticker_struct.guild_id
    end

    test "handles Interaction entity creation" do
      interaction_struct = %{
        id: 333_444_555,
        type: 2,
        guild_id: 666_777_888,
        channel_id: 999_000_111,
        user: %{id: 222_333_444},
        token: "interaction_token_123",
        data: %{"name" => "test_command", "options" => []}
      }

      result = TestApp.Discord.interaction_from_discord(%{discord_struct: interaction_struct})

      assert {:ok, created_interaction} = result
      assert created_interaction.discord_id == interaction_struct.id
      assert created_interaction.type == interaction_struct.type
      assert created_interaction.guild_id == interaction_struct.guild_id
      assert created_interaction.channel_id == interaction_struct.channel_id
      assert created_interaction.user_id == interaction_struct.user.id
      assert created_interaction.token == interaction_struct.token
      assert created_interaction.data == interaction_struct.data
    end

    test "API fallback works when no discord_struct provided" do
      # Create a mock that will be called by the API fetcher
      Mimic.copy(Nostrum.Api)

      # Mock successful API response
      Mimic.expect(Nostrum.Api, :get_user, fn 999_888_777 ->
        {:ok, user(%{id: 999_888_777, username: "api_fetched_user"})}
      end)

      # Call action without discord_struct, providing only discord_id
      result = TestApp.Discord.user_from_discord(%{discord_id: 999_888_777})

      assert {:ok, created_user} = result
      assert created_user.discord_id == 999_888_777
      assert created_user.discord_username == "api_fetched_user"
      assert created_user.email == "discord+999888777@discord.local"
    end

    test "API fallback handles API errors gracefully" do
      Mimic.copy(Nostrum.Api)

      # Mock API error response
      Mimic.expect(Nostrum.Api, :get_user, fn 999_888_777 ->
        {:error, %{status_code: 404, message: "User not found"}}
      end)

      # Call action without discord_struct
      result = TestApp.Discord.user_from_discord(%{discord_id: 999_888_777})

      assert {:error, error} = result
      assert error.message =~ "Failed to fetch user with ID 999888777"
    end

    test "API fallback handles unsupported entity types" do
      # Call with entity type that doesn't support API fetching
      result = TestApp.Discord.voice_state_from_discord(%{user_id: 123, channel_id: 456})

      assert {:error, error} = result
      assert error.message =~ "Failed to fetch voice_state"
      assert error.message =~ ":unsupported_type"
    end

    test "API fallback requires discord_id for supported types" do
      # Call user action without discord_id or discord_struct
      result = TestApp.Discord.user_from_discord(%{})

      assert {:error, error} = result
      assert error.message =~ "No Discord ID found for user entity"
    end

    test "Guild API fallback works correctly" do
      Mimic.copy(Nostrum.Api)

      # Mock successful guild API response
      Mimic.expect(Nostrum.Api, :get_guild, fn 888_777_666 ->
        {:ok, guild(%{id: 888_777_666, name: "API Fetched Guild"})}
      end)

      # Call action without discord_struct
      result = TestApp.Discord.guild_from_discord(%{discord_id: 888_777_666})

      assert {:ok, created_guild} = result
      assert created_guild.discord_id == 888_777_666
      assert created_guild.name == "API Fetched Guild"
    end
  end
end
