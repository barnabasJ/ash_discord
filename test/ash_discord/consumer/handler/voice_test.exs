defmodule AshDiscord.Consumer.Handler.VoiceTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators

  alias AshDiscord.Consumer.Handler.Voice
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/3" do
    @tag :fixed
    test "creates voice state in database with all relationships" do
      guild_data = guild()
      user_data = user()
      channel_data = channel(%{guild_id: guild_data.id})

      voice_state_data =
        voice_state(%{
          user_id: user_data.id,
          guild_id: guild_data.id,
          channel_id: channel_data.id
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceState,
        guild: nil,
        user: nil
      }

      voice_state_payload = Payloads.VoiceStateEvent.new!(voice_state_data)

      assert :ok = Voice.update(voice_state_payload, %Nostrum.Struct.WSState{}, context)

      [created_voice_state] =
        TestApp.Discord.VoiceState
        |> Ash.Query.load([:user, :guild, :channel])
        |> Ash.read!(authorize?: false)

      assert created_voice_state.user.discord_id == voice_state_data.user_id
      assert created_voice_state.guild.discord_id == voice_state_data.guild_id
      assert created_voice_state.channel.discord_id == voice_state_data.channel_id
      assert created_voice_state.session_id == voice_state_data.session_id
    end

    @tag :fixed
    test "updates existing voice state via upsert" do
      guild_data = guild()
      user_data = user()
      channel_data = channel(%{guild_id: guild_data.id})

      voice_state_data =
        voice_state(%{
          user_id: user_data.id,
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          self_mute: false,
          self_deaf: false
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceState,
        guild: nil,
        user: nil
      }

      voice_state_payload = Payloads.VoiceStateEvent.new!(voice_state_data)

      assert :ok = Voice.update(voice_state_payload, %Nostrum.Struct.WSState{}, context)

      updated_voice_state_data =
        voice_state(%{
          user_id: user_data.id,
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          session_id: voice_state_data.session_id,
          self_mute: true,
          self_deaf: true
        })

      updated_payload = Payloads.VoiceStateEvent.new!(updated_voice_state_data)

      assert :ok = Voice.update(updated_payload, %Nostrum.Struct.WSState{}, context)

      [updated_voice_state] =
        TestApp.Discord.VoiceState
        |> Ash.Query.load([:user, :guild, :channel])
        |> Ash.read!(authorize?: false)

      assert updated_voice_state.user.discord_id == user_data.id
      assert updated_voice_state.guild.discord_id == guild_data.id
      assert updated_voice_state.channel.discord_id == channel_data.id
      assert updated_voice_state.self_mute == true
      assert updated_voice_state.self_deaf == true
    end

    @tag :fixed
    test "handles voice state with nil channel_id (user left voice)" do
      guild_data = guild()
      user_data = user()

      voice_state_data =
        voice_state(%{
          user_id: user_data.id,
          guild_id: guild_data.id,
          channel_id: nil
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.user_from_discord!(%{data: user_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceState,
        guild: nil,
        user: nil
      }

      voice_state_payload = Payloads.VoiceStateEvent.new!(voice_state_data)

      assert :ok = Voice.update(voice_state_payload, %Nostrum.Struct.WSState{}, context)

      [created_voice_state] =
        TestApp.Discord.VoiceState
        |> Ash.Query.load([:user, :guild])
        |> Ash.read!(authorize?: false)

      assert created_voice_state.user.discord_id == voice_state_data.user_id
      assert created_voice_state.guild.discord_id == voice_state_data.guild_id
      assert created_voice_state.channel_discord_id == nil
    end
  end

  describe "ready/3" do
    @tag :fixed
    test "creates voice ready record in database with all relationships" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})

      voice_ready_data =
        voice_ready_event(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceReady,
        guild: nil,
        user: nil
      }

      voice_ready_payload = Payloads.VoiceReadyEvent.new!(voice_ready_data)

      assert :ok = Voice.ready(voice_ready_payload, %Nostrum.Struct.VoiceWSState{}, context)

      [created_record] =
        TestApp.Discord.VoiceReady
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert created_record.guild.discord_id == voice_ready_data.guild_id
      assert created_record.channel.discord_id == voice_ready_data.channel_id
    end

    @tag :fixed
    test "upserts voice ready record for same guild/channel" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})

      voice_ready_data =
        voice_ready_event(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceReady,
        guild: nil,
        user: nil
      }

      voice_ready_payload = Payloads.VoiceReadyEvent.new!(voice_ready_data)

      assert :ok = Voice.ready(voice_ready_payload, %Nostrum.Struct.VoiceWSState{}, context)
      assert :ok = Voice.ready(voice_ready_payload, %Nostrum.Struct.VoiceWSState{}, context)

      [record] =
        TestApp.Discord.VoiceReady
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert record.guild.discord_id == voice_ready_data.guild_id
      assert record.channel.discord_id == voice_ready_data.channel_id
    end
  end

  describe "server/3" do
    @tag :fixed
    test "creates voice server update record in database with all relationships" do
      guild_data = guild()

      voice_server_update_data =
        voice_server_update_event(%{
          guild_id: guild_data.id
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceServerUpdate,
        guild: nil,
        user: nil
      }

      voice_server_update_payload =
        Payloads.VoiceServerUpdateEvent.new!(voice_server_update_data)

      assert :ok =
               Voice.server(voice_server_update_payload, %Nostrum.Struct.WSState{}, context)

      [created_record] =
        TestApp.Discord.VoiceServerUpdate
        |> Ash.Query.load([:guild])
        |> Ash.read!(authorize?: false)

      assert created_record.guild.discord_id == voice_server_update_data.guild_id
      assert created_record.token == voice_server_update_data.token
      assert created_record.endpoint == voice_server_update_data.endpoint
    end

    @tag :fixed
    test "upserts voice server update for same guild" do
      guild_data = guild()
      first_token = Faker.UUID.v4()
      second_token = Faker.UUID.v4()

      voice_server_update_data_1 =
        voice_server_update_event(%{guild_id: guild_data.id, token: first_token})

      voice_server_update_data_2 =
        voice_server_update_event(%{guild_id: guild_data.id, token: second_token})

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceServerUpdate,
        guild: nil,
        user: nil
      }

      payload_1 = Payloads.VoiceServerUpdateEvent.new!(voice_server_update_data_1)
      payload_2 = Payloads.VoiceServerUpdateEvent.new!(voice_server_update_data_2)

      assert :ok = Voice.server(payload_1, %Nostrum.Struct.WSState{}, context)
      assert :ok = Voice.server(payload_2, %Nostrum.Struct.WSState{}, context)

      [updated_record] =
        TestApp.Discord.VoiceServerUpdate
        |> Ash.Query.load([:guild])
        |> Ash.read!(authorize?: false)

      assert updated_record.guild.discord_id == guild_data.id
      assert updated_record.token == second_token
    end

    @tag :fixed
    test "handles voice server update with nil endpoint" do
      guild_data = guild()

      voice_server_update_data =
        voice_server_update_event(%{
          guild_id: guild_data.id,
          endpoint: nil
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceServerUpdate,
        guild: nil,
        user: nil
      }

      voice_server_update_payload =
        Payloads.VoiceServerUpdateEvent.new!(voice_server_update_data)

      assert :ok =
               Voice.server(voice_server_update_payload, %Nostrum.Struct.WSState{}, context)

      [created_record] =
        TestApp.Discord.VoiceServerUpdate
        |> Ash.Query.load([:guild])
        |> Ash.read!(authorize?: false)

      assert created_record.guild.discord_id == guild_data.id
      assert created_record.endpoint == nil
    end
  end

  describe "speaking/3" do
    @tag :fixed
    test "creates voice speaking update record in database with all relationships" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})

      speaking_update_data =
        speaking_update_event(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          speaking: true
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceSpeakingUpdate,
        guild: nil,
        user: nil
      }

      speaking_update_payload =
        Payloads.VoiceSpeakingUpdateEvent.new!(speaking_update_data)

      assert :ok =
               Voice.speaking(speaking_update_payload, %Nostrum.Struct.VoiceWSState{}, context)

      [created_record] =
        TestApp.Discord.VoiceSpeakingUpdate
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert created_record.guild.discord_id == speaking_update_data.guild_id
      assert created_record.channel.discord_id == speaking_update_data.channel_id
      assert created_record.speaking == true
      assert created_record.timed_out == speaking_update_data.timed_out
    end

    @tag :fixed
    test "upserts speaking update for same channel/guild" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})

      speaking_update_data_1 =
        speaking_update_event(%{
          channel_id: channel_data.id,
          guild_id: guild_data.id,
          speaking: true
        })

      speaking_update_data_2 =
        speaking_update_event(%{
          channel_id: channel_data.id,
          guild_id: guild_data.id,
          speaking: false
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceSpeakingUpdate,
        guild: nil,
        user: nil
      }

      payload_1 = Payloads.VoiceSpeakingUpdateEvent.new!(speaking_update_data_1)
      payload_2 = Payloads.VoiceSpeakingUpdateEvent.new!(speaking_update_data_2)

      assert :ok = Voice.speaking(payload_1, %Nostrum.Struct.VoiceWSState{}, context)
      assert :ok = Voice.speaking(payload_2, %Nostrum.Struct.VoiceWSState{}, context)

      [updated_record] =
        TestApp.Discord.VoiceSpeakingUpdate
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert updated_record.guild.discord_id == guild_data.id
      assert updated_record.channel.discord_id == channel_data.id
      assert updated_record.speaking == false
    end

    @tag :fixed
    test "handles speaking update with current_url" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})

      speaking_update_data =
        speaking_update_event(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          speaking: true,
          current_url: "https://cdn.discordapp.com/audio.mp3"
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceSpeakingUpdate,
        guild: nil,
        user: nil
      }

      speaking_update_payload =
        Payloads.VoiceSpeakingUpdateEvent.new!(speaking_update_data)

      assert :ok =
               Voice.speaking(speaking_update_payload, %Nostrum.Struct.VoiceWSState{}, context)

      [created_record] =
        TestApp.Discord.VoiceSpeakingUpdate
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert created_record.guild.discord_id == guild_data.id
      assert created_record.channel.discord_id == channel_data.id
      assert created_record.current_url == "https://cdn.discordapp.com/audio.mp3"
    end

    @tag :fixed
    test "handles speaking update with timed_out true" do
      guild_data = guild()
      channel_data = channel(%{guild_id: guild_data.id})

      speaking_update_data =
        speaking_update_event(%{
          guild_id: guild_data.id,
          channel_id: channel_data.id,
          speaking: false,
          timed_out: true
        })

      TestApp.Discord.guild_from_discord!(%{data: guild_data}, authorize?: false)
      TestApp.Discord.channel_from_discord!(%{data: channel_data}, authorize?: false)

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceSpeakingUpdate,
        guild: nil,
        user: nil
      }

      speaking_update_payload =
        Payloads.VoiceSpeakingUpdateEvent.new!(speaking_update_data)

      assert :ok =
               Voice.speaking(speaking_update_payload, %Nostrum.Struct.VoiceWSState{}, context)

      [created_record] =
        TestApp.Discord.VoiceSpeakingUpdate
        |> Ash.Query.load([:guild, :channel])
        |> Ash.read!(authorize?: false)

      assert created_record.guild.discord_id == guild_data.id
      assert created_record.channel.discord_id == channel_data.id
      assert created_record.timed_out == true
    end
  end

  describe "incoming/3" do
    import ExUnit.CaptureLog

    test "calls configured action and logs packet data" do
      # VOICE_INCOMING_PACKET can have a configured action for logging/analytics
      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceIncoming,
        guild: nil,
        user: nil,
        context: %{private: %{ash_discord?: true}}
      }

      # Simulate rtp_opus tuple: {{sequence, timestamp, ssrc}, opus_packet}
      rtp_data = {{12345, 98765, 54321}, <<1, 2, 3, 4, 5>>}

      log =
        capture_log(fn ->
          assert :ok = Voice.incoming(rtp_data, %Nostrum.Struct.VoiceWSState{}, context)
        end)

      assert log =~ "Voice packet received"
    end
  end
end
