defmodule TestApp.Discord.VoiceIncoming do
  @moduledoc """
  Test resource for VOICE_INCOMING_PACKET events.
  """

  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord,
    data_layer: Ash.DataLayer.Ets

  require Logger

  ash_discord do
    events do
      on(:VOICE_INCOMING_PACKET, :log_packet)
    end
  end

  ets do
    private?(true)
  end

  actions do
    action :log_packet do
      argument(:data, :term, allow_nil?: false)

      run(fn input, _context ->
        Logger.error("Voice packet received: #{inspect(input.arguments.data)}")
        :ok
      end)
    end
  end
end
