defmodule AshDiscord.Consumer.Payloads.VoiceSpeakingUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord VOICE_SPEAKING_UPDATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.SpeakingUpdate.t()`.

  ## References
  - [Discord API - Voice](https://discord.com/developers/docs/topics/voice-connections)
  - [Nostrum - Event.SpeakingUpdate](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.SpeakingUpdate.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :channel_id, :integer, allow_nil?: false, description: "Channel ID"
    field :guild_id, :integer, allow_nil?: false, description: "Guild ID"
    field :speaking, :boolean, allow_nil?: false, description: "Whether the user is speaking"
    field :current_url, :string, description: "Current audio URL"

    field :timed_out, :boolean,
      allow_nil?: false,
      description: "Whether the speaking update timed out"
  end

  @doc """
  Create a VoiceSpeakingUpdateEvent TypedStruct from a Nostrum SpeakingUpdate event struct.

  Accepts a `Nostrum.Struct.Event.SpeakingUpdate.t()` and creates an AshDiscord VoiceSpeakingUpdateEvent TypedStruct.
  Also handles being passed a VoiceSpeakingUpdateEvent payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = voice_speaking_update_payload) do
    {:ok, voice_speaking_update_payload}
  end

  def new(%Nostrum.Struct.Event.SpeakingUpdate{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    super(attrs)
  end
end
