defmodule AshDiscord.Changes.FromDiscord.VoiceStateTest do
  @moduledoc """
  Comprehensive tests for VoiceState entity from_discord transformation.

  Tests struct-first pattern and upsert behavior. Voice states are ephemeral
  and not independently fetchable from API, so no API fallback pattern.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators
  use Mimic

  describe "struct-first pattern" do
    @tag :fixed
    test "creates voice state from discord struct with all attributes" do
      user_id = 123_456_789
      channel_id = 555_666_777
      guild_id = 111_222_333

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "voice-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      voice_state_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          session_id: "session_abc123",
          deaf: false,
          mute: false,
          self_deaf: false,
          self_mute: false,
          self_stream: false,
          self_video: false,
          suppress: false,
          member: nil
        })

      created_voice_state =
        TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct},
          load: [:user, :channel, :guild]
        )

      assert created_voice_state.session_id == voice_state_struct.session_id
      assert created_voice_state.deaf == false
      assert created_voice_state.mute == false
      assert created_voice_state.self_deaf == false
      assert created_voice_state.self_mute == false
      assert created_voice_state.suppress == false
      assert created_voice_state.user.discord_id == user_id
      assert created_voice_state.channel.discord_id == channel_id
      assert created_voice_state.guild.discord_id == guild_id
    end

    @tag :fixed
    test "handles server-deafened user" do
      user_id = 987_654_321
      channel_id = 777_888_999
      guild_id = 333_444_555

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "voice-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      voice_state_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          session_id: "session_def456",
          deaf: true,
          mute: false,
          self_deaf: false,
          self_mute: false,
          self_stream: false,
          self_video: false,
          suppress: false,
          member: nil
        })

      created_voice_state =
        TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct},
          load: [:user, :channel, :guild]
        )

      assert created_voice_state.user.discord_id == user_id
      assert created_voice_state.deaf == true
      assert created_voice_state.mute == false
    end

    @tag :fixed
    test "handles server-muted user" do
      user_id = 111_222_333
      channel_id = 444_555_666
      guild_id = 777_888_999

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "voice-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      voice_state_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          session_id: "session_ghi789",
          deaf: false,
          mute: true,
          self_deaf: false,
          self_mute: false,
          suppress: false,
          self_stream: false,
          self_video: false,
          member: nil
        })

      created_voice_state =
        TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct},
          load: [:user, :channel, :guild]
        )

      assert created_voice_state.user.discord_id == user_id
      assert created_voice_state.deaf == false
      assert created_voice_state.mute == true
    end

    @tag :fixed
    test "handles self-deafened user" do
      user_id = 555_666_777
      channel_id = 888_999_111
      guild_id = 222_333_444

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "voice-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      voice_state_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          session_id: "session_jkl012",
          deaf: false,
          mute: false,
          self_deaf: true,
          self_mute: false,
          suppress: false,
          self_stream: false,
          self_video: false,
          member: nil
        })

      created_voice_state =
        TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct},
          load: [:user, :channel, :guild]
        )

      assert created_voice_state.user.discord_id == user_id
      assert created_voice_state.self_deaf == true
      assert created_voice_state.self_mute == false
    end

    @tag :fixed
    test "handles self-muted user" do
      user_id = 777_888_999
      channel_id = 111_222_333
      guild_id = 444_555_666

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "voice-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      voice_state_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          session_id: "session_mno345",
          deaf: false,
          mute: false,
          self_deaf: false,
          self_mute: true,
          suppress: false,
          self_stream: false,
          self_video: false,
          member: nil
        })

      created_voice_state =
        TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct},
          load: [:user, :channel, :guild]
        )

      assert created_voice_state.user.discord_id == user_id
      assert created_voice_state.self_deaf == false
      assert created_voice_state.self_mute == true
    end

    @tag :fixed
    test "handles suppressed user" do
      user_id = 333_444_555
      channel_id = 666_777_888
      guild_id = 999_111_222

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn ^channel_id ->
        {:ok, channel(%{id: channel_id, name: "voice-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      voice_state_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: channel_id,
          guild_id: guild_id,
          session_id: "session_pqr678",
          deaf: false,
          mute: false,
          self_deaf: false,
          self_mute: false,
          suppress: true
        })

      created_voice_state =
        TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct},
          load: [:user, :channel, :guild]
        )

      assert created_voice_state.user.discord_id == user_id
      assert created_voice_state.suppress == true
    end

    @tag :fixed
    test "handles user leaving voice channel" do
      user_id = 999_111_222
      guild_id = 333_444_555

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      voice_state_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: nil,
          guild_id: guild_id,
          session_id: "session_stu901",
          deaf: false,
          mute: false,
          self_deaf: false,
          self_mute: false,
          suppress: false,
          self_stream: false,
          self_video: false,
          member: nil
        })

      created_voice_state =
        TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct},
          load: [:user, :guild]
        )

      assert created_voice_state.user.discord_id == user_id
      assert created_voice_state.channel_id == nil
      assert created_voice_state.guild.discord_id == guild_id
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing voice state instead of creating duplicate" do
      user_id = 555_666_777
      guild_id = 111_222_333
      initial_channel_id = 888_999_111
      updated_channel_id = 222_333_444

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn channel_id ->
        {:ok, channel(%{id: channel_id, name: "voice-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      initial_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: initial_channel_id,
          guild_id: guild_id,
          session_id: "session_original",
          deaf: false,
          mute: false,
          self_deaf: false,
          self_mute: false,
          suppress: false,
          self_stream: false,
          self_video: false,
          member: nil
        })

      original_voice_state =
        TestApp.Discord.voice_state_from_discord!(%{data: initial_struct},
          load: [:user, :channel, :guild]
        )

      updated_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: updated_channel_id,
          guild_id: guild_id,
          session_id: "session_updated",
          deaf: true,
          mute: true,
          self_deaf: true,
          self_mute: true,
          suppress: true
        })

      updated_voice_state =
        TestApp.Discord.voice_state_from_discord!(%{data: updated_struct},
          load: [:user, :channel, :guild]
        )

      assert updated_voice_state.id == original_voice_state.id
      assert updated_voice_state.user.discord_id == user_id
      assert updated_voice_state.guild.discord_id == guild_id
      assert updated_voice_state.channel.discord_id == updated_channel_id
      assert updated_voice_state.session_id == "session_updated"
      assert updated_voice_state.deaf == true
      assert updated_voice_state.mute == true
      assert updated_voice_state.self_deaf == true
      assert updated_voice_state.self_mute == true
      assert updated_voice_state.suppress == true
    end

    @tag :fixed
    test "upsert works with channel changes" do
      user_id = 333_444_555
      guild_id = 777_888_999
      initial_channel_id = 111_222_333
      updated_channel_id = 666_777_888

      Mimic.expect(Nostrum.Api.User, :get, fn ^user_id ->
        {:ok, user(%{id: user_id, username: "test_user_#{user_id}"})}
      end)

      Mimic.expect(Nostrum.Api.Channel, :get, fn channel_id ->
        {:ok, channel(%{id: channel_id, name: "voice-channel"})}
      end)

      Mimic.expect(Nostrum.Api.Guild, :get, fn ^guild_id ->
        {:ok, guild(%{id: guild_id, name: "Test Guild"})}
      end)

      initial_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: initial_channel_id,
          guild_id: guild_id,
          session_id: "session_same",
          deaf: false,
          mute: false
        })

      original_voice_state =
        TestApp.Discord.voice_state_from_discord!(%{data: initial_struct},
          load: [:user, :channel, :guild]
        )

      updated_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: updated_channel_id,
          guild_id: guild_id,
          session_id: "session_same",
          deaf: false,
          mute: false
        })

      updated_voice_state =
        TestApp.Discord.voice_state_from_discord!(%{data: updated_struct},
          load: [:user, :channel, :guild]
        )

      assert updated_voice_state.id == original_voice_state.id
      assert updated_voice_state.user.discord_id == user_id
      assert updated_voice_state.guild.discord_id == guild_id
      assert updated_voice_state.channel.discord_id == updated_channel_id
    end
  end
end
