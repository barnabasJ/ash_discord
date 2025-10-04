defmodule AshDiscord.Consumer.Handler.VoiceTest do
  use TestApp.DataCase, async: false

  import AshDiscord.Test.Generators.Discord

  alias AshDiscord.Consumer.Handler.Voice
  alias AshDiscord.Consumer.Payloads
  alias TestApp.TestConsumer

  describe "update/4" do
    test "creates voice state in database" do
      voice_state_data = voice_state()

      context = %AshDiscord.Context{
        consumer: TestConsumer,
        resource: nil,
        guild: nil,
        user: nil
      }

      {:ok, voice_state_event} = Payloads.VoiceStateEvent.new(voice_state_data)

      assert :ok =
               Voice.update(TestConsumer, voice_state_event, %Nostrum.Struct.WSState{}, context)

      # Verify voice state was created in database
      voice_states = TestApp.Discord.VoiceState.read!()
      assert length(voice_states) == 1

      created_state = hd(voice_states)
      assert created_state.user_id == voice_state_data.user_id
      assert created_state.channel_id == voice_state_data.channel_id
      assert created_state.guild_id == voice_state_data.guild_id
    end
  end
end
