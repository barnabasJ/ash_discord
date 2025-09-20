defmodule AshDiscord.Changes.FromDiscord.VoiceStateTest do
  @moduledoc """
  Comprehensive tests for VoiceState entity from_discord transformation.

  Tests both struct-first and API fallback patterns, plus upsert behavior.
  """

  use TestApp.DataCase, async: false
  import AshDiscord.Test.Generators.Discord

  describe "struct-first pattern" do
    test "creates voice state from discord struct with all attributes" do
      voice_state_struct =
        voice_state(%{
          user_id: 123_456_789,
          channel_id: 555_666_777,
          guild_id: 111_222_333,
          session_id: "session_abc123",
          deaf: false,
          mute: false,
          self_deaf: false,
          self_mute: false,
          suppress: false
        })

      result = TestApp.Discord.voice_state_from_discord(%{discord_struct: voice_state_struct})

      assert {:ok, created_voice_state} = result
      assert created_voice_state.user_id == voice_state_struct.user_id
      assert created_voice_state.channel_id == voice_state_struct.channel_id
      assert created_voice_state.guild_id == voice_state_struct.guild_id
      assert created_voice_state.session_id == voice_state_struct.session_id
      assert created_voice_state.deaf == false
      assert created_voice_state.mute == false
      assert created_voice_state.self_deaf == false
      assert created_voice_state.self_mute == false
      assert created_voice_state.suppress == false
    end

    test "handles server-deafened user" do
      voice_state_struct =
        voice_state(%{
          user_id: 987_654_321,
          channel_id: 777_888_999,
          guild_id: 333_444_555,
          session_id: "session_def456",
          deaf: true,
          mute: false,
          self_deaf: false,
          self_mute: false,
          suppress: false
        })

      result = TestApp.Discord.voice_state_from_discord(%{discord_struct: voice_state_struct})

      assert {:ok, created_voice_state} = result
      assert created_voice_state.user_id == voice_state_struct.user_id
      assert created_voice_state.deaf == true
      assert created_voice_state.mute == false
    end

    test "handles server-muted user" do
      voice_state_struct =
        voice_state(%{
          user_id: 111_222_333,
          channel_id: 444_555_666,
          guild_id: 777_888_999,
          session_id: "session_ghi789",
          deaf: false,
          mute: true,
          self_deaf: false,
          self_mute: false,
          suppress: false
        })

      result = TestApp.Discord.voice_state_from_discord(%{discord_struct: voice_state_struct})

      assert {:ok, created_voice_state} = result
      assert created_voice_state.user_id == voice_state_struct.user_id
      assert created_voice_state.deaf == false
      assert created_voice_state.mute == true
    end

    test "handles self-deafened user" do
      voice_state_struct =
        voice_state(%{
          user_id: 555_666_777,
          channel_id: 888_999_111,
          guild_id: 222_333_444,
          session_id: "session_jkl012",
          deaf: false,
          mute: false,
          self_deaf: true,
          self_mute: false,
          suppress: false
        })

      result = TestApp.Discord.voice_state_from_discord(%{discord_struct: voice_state_struct})

      assert {:ok, created_voice_state} = result
      assert created_voice_state.user_id == voice_state_struct.user_id
      assert created_voice_state.self_deaf == true
      assert created_voice_state.self_mute == false
    end

    test "handles self-muted user" do
      voice_state_struct =
        voice_state(%{
          user_id: 777_888_999,
          channel_id: 111_222_333,
          guild_id: 444_555_666,
          session_id: "session_mno345",
          deaf: false,
          mute: false,
          self_deaf: false,
          self_mute: true,
          suppress: false
        })

      result = TestApp.Discord.voice_state_from_discord(%{discord_struct: voice_state_struct})

      assert {:ok, created_voice_state} = result
      assert created_voice_state.user_id == voice_state_struct.user_id
      assert created_voice_state.self_deaf == false
      assert created_voice_state.self_mute == true
    end

    test "handles suppressed user" do
      voice_state_struct =
        voice_state(%{
          user_id: 333_444_555,
          channel_id: 666_777_888,
          guild_id: 999_111_222,
          session_id: "session_pqr678",
          deaf: false,
          mute: false,
          self_deaf: false,
          self_mute: false,
          suppress: true
        })

      result = TestApp.Discord.voice_state_from_discord(%{discord_struct: voice_state_struct})

      assert {:ok, created_voice_state} = result
      assert created_voice_state.user_id == voice_state_struct.user_id
      assert created_voice_state.suppress == true
    end

    test "handles user leaving voice channel" do
      voice_state_struct =
        voice_state(%{
          user_id: 999_111_222,
          # User left channel
          channel_id: nil,
          guild_id: 333_444_555,
          session_id: "session_stu901",
          deaf: false,
          mute: false,
          self_deaf: false,
          self_mute: false,
          suppress: false
        })

      result = TestApp.Discord.voice_state_from_discord(%{discord_struct: voice_state_struct})

      assert {:ok, created_voice_state} = result
      assert created_voice_state.user_id == voice_state_struct.user_id
      assert created_voice_state.channel_id == nil
    end
  end

  describe "API fallback pattern" do
    test "voice state API fallback is not supported" do
      # Voice states don't support direct API fetching in our implementation
      discord_id = 999_888_777

      result = TestApp.Discord.voice_state_from_discord(%{discord_id: discord_id})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No such input `discord_id`"
    end

    test "requires discord_struct for voice state creation" do
      result = TestApp.Discord.voice_state_from_discord(%{})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "No Discord ID found for voice_state entity"
    end
  end

  describe "upsert behavior" do
    test "updates existing voice state instead of creating duplicate" do
      user_id = 555_666_777
      guild_id = 111_222_333

      # Create initial voice state
      initial_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: 888_999_111,
          guild_id: guild_id,
          session_id: "session_original",
          deaf: false,
          mute: false,
          self_deaf: false,
          self_mute: false,
          suppress: false
        })

      {:ok, original_voice_state} =
        TestApp.Discord.voice_state_from_discord(%{discord_struct: initial_struct})

      # Update same user's voice state
      updated_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: 222_333_444,
          guild_id: guild_id,
          session_id: "session_updated",
          deaf: true,
          mute: true,
          self_deaf: true,
          self_mute: true,
          suppress: true
        })

      {:ok, updated_voice_state} =
        TestApp.Discord.voice_state_from_discord(%{discord_struct: updated_struct})

      # Should be same record (same Ash ID)
      assert updated_voice_state.id == original_voice_state.id
      assert updated_voice_state.user_id == original_voice_state.user_id
      assert updated_voice_state.guild_id == original_voice_state.guild_id

      # But with updated attributes
      assert updated_voice_state.channel_id == 222_333_444
      assert updated_voice_state.session_id == "session_updated"
      assert updated_voice_state.deaf == true
      assert updated_voice_state.mute == true
      assert updated_voice_state.self_deaf == true
      assert updated_voice_state.self_mute == true
      assert updated_voice_state.suppress == true
    end

    test "upsert works with channel changes" do
      user_id = 333_444_555
      guild_id = 777_888_999

      # Create initial voice state in one channel
      initial_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: 111_222_333,
          guild_id: guild_id,
          session_id: "session_same",
          deaf: false,
          mute: false
        })

      {:ok, original_voice_state} =
        TestApp.Discord.voice_state_from_discord(%{discord_struct: initial_struct})

      # Move to different channel
      updated_struct =
        voice_state(%{
          user_id: user_id,
          channel_id: 666_777_888,
          guild_id: guild_id,
          session_id: "session_same",
          deaf: false,
          mute: false
        })

      {:ok, updated_voice_state} =
        TestApp.Discord.voice_state_from_discord(%{discord_struct: updated_struct})

      # Should be same record
      assert updated_voice_state.id == original_voice_state.id
      assert updated_voice_state.user_id == user_id
      assert updated_voice_state.guild_id == guild_id

      # But with updated channel
      assert updated_voice_state.channel_id == 666_777_888
    end
  end

  describe "error handling" do
    test "handles invalid discord_struct format" do
      result = TestApp.Discord.voice_state_from_discord(%{discord_struct: "not_a_map"})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "Invalid value provided for discord_struct"
    end

    test "handles missing required fields in discord_struct" do
      # Missing required fields
      invalid_struct = voice_state(%{user_id: nil, session_id: nil})

      result = TestApp.Discord.voice_state_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is required"
    end

    test "handles invalid user_id in discord_struct" do
      invalid_struct = %{
        # Invalid user_id type
        user_id: "not_an_integer",
        channel_id: 555_666_777,
        guild_id: 111_222_333,
        session_id: "session_test"
      }

      result = TestApp.Discord.voice_state_from_discord(%{discord_struct: invalid_struct})

      assert {:error, error} = result
      error_message = Exception.message(error)
      assert error_message =~ "is invalid" or error_message =~ "must be"
    end
  end
end
