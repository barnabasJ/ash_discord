defmodule AshDiscord.Changes.FromDiscord.VoiceStateTest do
  @moduledoc """
  Comprehensive tests for VoiceState entity from_discord transformation.

  Tests struct-first pattern and upsert behavior. Voice states are ephemeral
  events and not independently fetchable from Discord API, so no API fallback tests.
  """

  use TestApp.DataCase, async: true
  import AshDiscord.Test.Generators

  describe "struct-first pattern" do
    @tag :fixed
    test "creates voice state from discord struct with all attributes" do
      user_id = 123_456_789
      channel_id = 555_666_777
      guild_id = 111_222_333

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

      created = TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct})

      assert created.user_discord_id == user_id
      assert created.channel_discord_id == channel_id
      assert created.guild_discord_id == guild_id
      assert created.session_id == voice_state_struct.session_id
      assert created.deaf == false
      assert created.mute == false
      assert created.self_deaf == false
      assert created.self_mute == false
      assert created.suppress == false
    end

    @tag :fixed
    test "handles server-deafened user" do
      user_id = 987_654_321
      channel_id = 777_888_999
      guild_id = 333_444_555

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

      created = TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct})

      assert created.user_discord_id == user_id
      assert created.channel_discord_id == channel_id
      assert created.guild_discord_id == guild_id
      assert created.deaf == true
      assert created.mute == false
    end

    @tag :fixed
    test "handles server-muted user" do
      user_id = 111_222_333
      channel_id = 444_555_666
      guild_id = 777_888_999

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

      created = TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct})

      assert created.user_discord_id == user_id
      assert created.channel_discord_id == channel_id
      assert created.guild_discord_id == guild_id
      assert created.deaf == false
      assert created.mute == true
    end

    @tag :fixed
    test "handles self-deafened user" do
      user_id = 555_666_777
      channel_id = 888_999_111
      guild_id = 222_333_444

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

      created = TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct})

      assert created.user_discord_id == user_id
      assert created.channel_discord_id == channel_id
      assert created.guild_discord_id == guild_id
      assert created.self_deaf == true
      assert created.self_mute == false
    end

    @tag :fixed
    test "handles self-muted user" do
      user_id = 777_888_999
      channel_id = 111_222_333
      guild_id = 444_555_666

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

      created = TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct})

      assert created.user_discord_id == user_id
      assert created.channel_discord_id == channel_id
      assert created.guild_discord_id == guild_id
      assert created.self_deaf == false
      assert created.self_mute == true
    end

    @tag :fixed
    test "handles suppressed user" do
      user_id = 333_444_555
      channel_id = 666_777_888
      guild_id = 999_111_222

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

      created = TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct})

      assert created.user_discord_id == user_id
      assert created.channel_discord_id == channel_id
      assert created.guild_discord_id == guild_id
      assert created.suppress == true
    end

    @tag :fixed
    test "handles user leaving voice channel" do
      user_id = 999_111_222
      guild_id = 333_444_555

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

      created = TestApp.Discord.voice_state_from_discord!(%{data: voice_state_struct})

      assert created.user_discord_id == user_id
      assert created.guild_discord_id == guild_id
      assert created.channel_discord_id == nil
    end
  end

  describe "upsert behavior" do
    @tag :fixed
    test "updates existing voice state instead of creating duplicate" do
      user_id = 555_666_777
      guild_id = 111_222_333
      initial_channel_id = 888_999_111
      updated_channel_id = 222_333_444

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

      original = TestApp.Discord.voice_state_from_discord!(%{data: initial_struct})

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

      updated = TestApp.Discord.voice_state_from_discord!(%{data: updated_struct})

      assert updated.id == original.id
      assert updated.user_discord_id == original.user_discord_id
      assert updated.guild_discord_id == original.guild_discord_id

      assert updated.channel_discord_id == updated_channel_id
      assert updated.session_id == "session_updated"
      assert updated.deaf == true
      assert updated.mute == true
      assert updated.self_deaf == true
      assert updated.self_mute == true
      assert updated.suppress == true
    end

    @tag :fixed
    test "upsert works with channel changes" do
      user_id = 333_444_555
      guild_id = 777_888_999
      initial_channel_id = 111_222_333
      updated_channel_id = 666_777_888

      initial_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: initial_channel_id,
          guild_id: guild_id,
          session_id: "session_same",
          deaf: false,
          mute: false
        })

      original = TestApp.Discord.voice_state_from_discord!(%{data: initial_struct})

      updated_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: updated_channel_id,
          guild_id: guild_id,
          session_id: "session_same",
          deaf: false,
          mute: false
        })

      updated = TestApp.Discord.voice_state_from_discord!(%{data: updated_struct})

      assert updated.id == original.id
      assert updated.user_discord_id == user_id
      assert updated.guild_discord_id == guild_id

      assert updated.channel_discord_id == updated_channel_id
    end
  end
end
