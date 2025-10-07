defmodule AshDiscord.Consumer.Handler.VoiceTest do
  use TestApp.DataCase, async: true

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Consumer.Handler.Voice
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/3" do
    test "creates voice state in database" do
      voice_state_data = voice_state()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceState,
        guild: nil,
        user: nil
      }

      {:ok, voice_state_payload} = Payloads.VoiceStateEvent.new(voice_state_data)

      assert :ok = Voice.update(voice_state_payload, %Nostrum.Struct.WSState{}, context)

      # Verify voice state was created in database
      voice_states = TestApp.Discord.VoiceState.read!()
      assert length(voice_states) == 1

      created_voice_state = hd(voice_states)
      assert created_voice_state.user_id == voice_state_data.user_id
      assert created_voice_state.channel_id == voice_state_data.channel_id
      assert created_voice_state.session_id == voice_state_data.session_id
    end

    test "updates existing voice state via upsert" do
      # Use fixed IDs to avoid generator randomness interfering with upsert
      user_id = generate_snowflake()
      guild_id = generate_snowflake()
      channel_id = generate_snowflake()
      session_id = Faker.UUID.v4()

      voice_state_data =
        voice_state(%{
          user_id: user_id,
          guild_id: guild_id,
          channel_id: channel_id,
          session_id: session_id,
          self_mute: false,
          self_deaf: false
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceState,
        guild: nil,
        user: nil
      }

      {:ok, voice_state_payload} = Payloads.VoiceStateEvent.new(voice_state_data)

      # Create initial voice state
      assert :ok = Voice.update(voice_state_payload, %Nostrum.Struct.WSState{}, context)

      # Update with same identity but different mute/deaf state
      updated_voice_state_data =
        voice_state(%{
          user_id: user_id,
          guild_id: guild_id,
          channel_id: channel_id,
          session_id: session_id,
          self_mute: true,
          self_deaf: true
        })

      {:ok, updated_payload} = Payloads.VoiceStateEvent.new(updated_voice_state_data)

      assert :ok = Voice.update(updated_payload, %Nostrum.Struct.WSState{}, context)

      # Verify only one record exists and it was updated
      voice_states = TestApp.Discord.VoiceState.read!()
      assert length(voice_states) == 1

      updated_voice_state = hd(voice_states)
      assert updated_voice_state.self_mute == true
      assert updated_voice_state.self_deaf == true
    end

    test "handles voice state with nil channel_id (user left voice)" do
      voice_state_data = voice_state(%{channel_id: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceState,
        guild: nil,
        user: nil
      }

      {:ok, voice_state_payload} = Payloads.VoiceStateEvent.new(voice_state_data)

      assert :ok = Voice.update(voice_state_payload, %Nostrum.Struct.WSState{}, context)

      # Verify voice state was created with nil channel_id
      voice_states = TestApp.Discord.VoiceState.read!()
      assert length(voice_states) == 1

      created_voice_state = hd(voice_states)
      assert created_voice_state.channel_id == nil
    end
  end

  describe "ready/3" do
    test "creates voice ready record in database" do
      voice_ready_data = voice_ready_event()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceReady,
        guild: nil,
        user: nil
      }

      {:ok, voice_ready_payload} = Payloads.VoiceReadyEvent.new(voice_ready_data)

      assert :ok = Voice.ready(voice_ready_payload, %Nostrum.Struct.VoiceWSState{}, context)

      # Verify voice ready event was recorded
      voice_ready_records = TestApp.Discord.VoiceReady.read!()
      assert length(voice_ready_records) == 1

      created_record = hd(voice_ready_records)
      assert created_record.channel_id == voice_ready_data.channel_id
      assert created_record.guild_id == voice_ready_data.guild_id
    end

    test "upserts voice ready record for same guild/channel" do
      voice_ready_data = voice_ready_event()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceReady,
        guild: nil,
        user: nil
      }

      {:ok, voice_ready_payload} = Payloads.VoiceReadyEvent.new(voice_ready_data)

      # Create initial record
      assert :ok = Voice.ready(voice_ready_payload, %Nostrum.Struct.VoiceWSState{}, context)

      # Create another with same IDs (simulates reconnection)
      assert :ok = Voice.ready(voice_ready_payload, %Nostrum.Struct.VoiceWSState{}, context)

      # Should still only have one record due to upsert
      voice_ready_records = TestApp.Discord.VoiceReady.read!()
      assert length(voice_ready_records) == 1
    end
  end

  describe "server/3" do
    test "creates voice server update record in database" do
      voice_server_update_data = voice_server_update_event()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceServerUpdate,
        guild: nil,
        user: nil
      }

      {:ok, voice_server_update_payload} =
        Payloads.VoiceServerUpdateEvent.new(voice_server_update_data)

      assert :ok =
               Voice.server(voice_server_update_payload, %Nostrum.Struct.WSState{}, context)

      # Verify voice server update event was recorded
      voice_server_update_records = TestApp.Discord.VoiceServerUpdate.read!()
      assert length(voice_server_update_records) == 1

      created_record = hd(voice_server_update_records)
      assert created_record.token == voice_server_update_data.token
      assert created_record.guild_id == voice_server_update_data.guild_id
      assert created_record.endpoint == voice_server_update_data.endpoint
    end

    test "upserts voice server update for same guild" do
      guild_id = generate_snowflake()
      first_token = Faker.UUID.v4()
      second_token = Faker.UUID.v4()

      voice_server_update_data_1 =
        voice_server_update_event(%{guild_id: guild_id, token: first_token})

      voice_server_update_data_2 =
        voice_server_update_event(%{guild_id: guild_id, token: second_token})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceServerUpdate,
        guild: nil,
        user: nil
      }

      {:ok, payload_1} = Payloads.VoiceServerUpdateEvent.new(voice_server_update_data_1)
      {:ok, payload_2} = Payloads.VoiceServerUpdateEvent.new(voice_server_update_data_2)

      # Create initial record
      assert :ok = Voice.server(payload_1, %Nostrum.Struct.WSState{}, context)

      # Update with new token for same guild
      assert :ok = Voice.server(payload_2, %Nostrum.Struct.WSState{}, context)

      # Should only have one record with updated token
      voice_server_update_records = TestApp.Discord.VoiceServerUpdate.read!()
      assert length(voice_server_update_records) == 1

      updated_record = hd(voice_server_update_records)
      assert updated_record.token == second_token
      assert updated_record.guild_id == guild_id
    end

    test "handles voice server update with nil endpoint" do
      voice_server_update_data = voice_server_update_event(%{endpoint: nil})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceServerUpdate,
        guild: nil,
        user: nil
      }

      {:ok, voice_server_update_payload} =
        Payloads.VoiceServerUpdateEvent.new(voice_server_update_data)

      assert :ok =
               Voice.server(voice_server_update_payload, %Nostrum.Struct.WSState{}, context)

      # Verify record was created with nil endpoint
      voice_server_update_records = TestApp.Discord.VoiceServerUpdate.read!()
      assert length(voice_server_update_records) == 1

      created_record = hd(voice_server_update_records)
      assert created_record.endpoint == nil
    end
  end

  describe "speaking/3" do
    test "creates voice speaking update record in database" do
      speaking_update_data = speaking_update_event(%{speaking: true})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceSpeakingUpdate,
        guild: nil,
        user: nil
      }

      {:ok, speaking_update_payload} =
        Payloads.VoiceSpeakingUpdateEvent.new(speaking_update_data)

      assert :ok =
               Voice.speaking(speaking_update_payload, %Nostrum.Struct.VoiceWSState{}, context)

      # Verify speaking update event was recorded
      speaking_update_records = TestApp.Discord.VoiceSpeakingUpdate.read!()
      assert length(speaking_update_records) == 1

      created_record = hd(speaking_update_records)
      assert created_record.channel_id == speaking_update_data.channel_id
      assert created_record.guild_id == speaking_update_data.guild_id
      assert created_record.speaking == true
      assert created_record.timed_out == speaking_update_data.timed_out
    end

    test "upserts speaking update for same channel/guild" do
      channel_id = generate_snowflake()
      guild_id = generate_snowflake()

      speaking_update_data_1 =
        speaking_update_event(%{channel_id: channel_id, guild_id: guild_id, speaking: true})

      speaking_update_data_2 =
        speaking_update_event(%{channel_id: channel_id, guild_id: guild_id, speaking: false})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceSpeakingUpdate,
        guild: nil,
        user: nil
      }

      {:ok, payload_1} = Payloads.VoiceSpeakingUpdateEvent.new(speaking_update_data_1)
      {:ok, payload_2} = Payloads.VoiceSpeakingUpdateEvent.new(speaking_update_data_2)

      # Create initial record (speaking started)
      assert :ok = Voice.speaking(payload_1, %Nostrum.Struct.VoiceWSState{}, context)

      # Update (speaking stopped)
      assert :ok = Voice.speaking(payload_2, %Nostrum.Struct.VoiceWSState{}, context)

      # Should only have one record with updated speaking state
      speaking_update_records = TestApp.Discord.VoiceSpeakingUpdate.read!()
      assert length(speaking_update_records) == 1

      updated_record = hd(speaking_update_records)
      assert updated_record.speaking == false
    end

    test "handles speaking update with current_url" do
      speaking_update_data =
        speaking_update_event(%{
          speaking: true,
          current_url: "https://cdn.discordapp.com/audio.mp3"
        })

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceSpeakingUpdate,
        guild: nil,
        user: nil
      }

      {:ok, speaking_update_payload} =
        Payloads.VoiceSpeakingUpdateEvent.new(speaking_update_data)

      assert :ok =
               Voice.speaking(speaking_update_payload, %Nostrum.Struct.VoiceWSState{}, context)

      # Verify record includes current_url
      speaking_update_records = TestApp.Discord.VoiceSpeakingUpdate.read!()
      assert length(speaking_update_records) == 1

      created_record = hd(speaking_update_records)
      assert created_record.current_url == "https://cdn.discordapp.com/audio.mp3"
    end

    test "handles speaking update with timed_out true" do
      speaking_update_data = speaking_update_event(%{speaking: false, timed_out: true})

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: TestApp.Discord.VoiceSpeakingUpdate,
        guild: nil,
        user: nil
      }

      {:ok, speaking_update_payload} =
        Payloads.VoiceSpeakingUpdateEvent.new(speaking_update_data)

      assert :ok =
               Voice.speaking(speaking_update_payload, %Nostrum.Struct.VoiceWSState{}, context)

      # Verify record includes timed_out flag
      speaking_update_records = TestApp.Discord.VoiceSpeakingUpdate.read!()
      assert length(speaking_update_records) == 1

      created_record = hd(speaking_update_records)
      assert created_record.timed_out == true
    end
  end

  describe "incoming/3" do
    test "returns :ok without error (informational handler)" do
      # VOICE_INCOMING_PACKET is a special case - it's raw audio data
      # The handler exists for compatibility but doesn't process the data
      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      # Simulate rtp_opus tuple: {{sequence, timestamp, ssrc}, opus_packet}
      rtp_data = {{12345, 98765, 54321}, <<1, 2, 3, 4, 5>>}

      assert :ok = Voice.incoming(rtp_data, %Nostrum.Struct.VoiceWSState{}, context)
    end
  end
end
