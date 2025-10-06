defmodule AshDiscord.Consumer.Payloads.VoiceReadyEvent do
  @moduledoc """
  TypedStruct wrapper for Discord VOICE_READY event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.VoiceReady.t()`.

  ## References
  - [Discord API - Voice](https://discord.com/developers/docs/topics/voice-connections)
  - [Nostrum - Event.VoiceReady](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.VoiceReady.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :channel_id, :integer,
      allow_nil?: false,
      description: "Id of the channel that voice is ready in"

    field :guild_id, :integer, allow_nil?: false, description: "Guild that voice is ready in"
  end

  @doc """
  Create a VoiceReadyEvent TypedStruct from a Nostrum VoiceReady event struct.

  Accepts a `Nostrum.Struct.Event.VoiceReady.t()` and creates an AshDiscord VoiceReadyEvent TypedStruct.
  Also handles being passed a VoiceReadyEvent payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = voice_ready_payload) do
    {:ok, voice_ready_payload}
  end

  def new(%Nostrum.Struct.Event.VoiceReady{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
