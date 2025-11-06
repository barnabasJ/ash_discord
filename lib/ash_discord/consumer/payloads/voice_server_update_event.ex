defmodule AshDiscord.Consumer.Payloads.VoiceServerUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord VOICE_SERVER_UPDATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.VoiceServerUpdate.t()`.

  ## References
  - [Discord API - Voice Server Update Event](https://discord.com/developers/docs/topics/gateway-events#voice-server-update)
  - [Nostrum - Event.VoiceServerUpdate](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.VoiceServerUpdate.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :token, :string, allow_nil?: false, description: "Voice connection token"

    field :guild_id, :integer,
      allow_nil?: false,
      description: "Guild ID this voice server update is for"

    field :endpoint, :string, description: "Voice server host"
  end

  @doc """
  Create a VoiceServerUpdateEvent TypedStruct from a Nostrum VoiceServerUpdate event struct.

  Accepts a `Nostrum.Struct.Event.VoiceServerUpdate.t()` and creates an AshDiscord VoiceServerUpdateEvent TypedStruct.
  Also handles being passed a VoiceServerUpdateEvent payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = voice_server_update_payload) do
    {:ok, voice_server_update_payload}
  end

  def new(%Nostrum.Struct.Event.VoiceServerUpdate{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    super(attrs)
  end
end
