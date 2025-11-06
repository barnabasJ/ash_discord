defmodule AshDiscord.Consumer.Payloads.VoiceState do
  @moduledoc """
  TypedStruct wrapper for Discord Voice State data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.VoiceState.t()`.
  This is an alias to VoiceStateEvent for consistency with other payload types.

  ## References
  - [Discord API - Voice State](https://discord.com/developers/docs/resources/voice#voice-state-object)
  - [Nostrum - Event.VoiceState](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.VoiceState.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: true,
      description:
        "Guild ID this voice state is for (optional, only present for guild voice channels)"

    field :channel_id, :integer,
      allow_nil?: true,
      description: "Channel ID this voice state is for (nil if user left voice)"

    field :user_id, :integer, allow_nil?: false, description: "User ID this voice state is for"

    field :member, AshDiscord.Consumer.Payloads.Member,
      allow_nil?: true,
      description: "Guild member this voice state is for (optional)"

    field :session_id, :string, allow_nil?: false, description: "Session ID for this voice state"

    field :deaf, :boolean,
      allow_nil?: false,
      description: "Whether this user is deafened by the server"

    field :mute, :boolean,
      allow_nil?: false,
      description: "Whether this user is muted by the server"

    field :self_deaf, :boolean,
      allow_nil?: false,
      description: "Whether this user is locally deafened"

    field :self_mute, :boolean,
      allow_nil?: false,
      description: "Whether this user is locally muted"

    field :self_stream, :boolean,
      allow_nil?: false,
      description: "Whether this user is streaming using Go Live"

    field :self_video, :boolean,
      allow_nil?: false,
      description: "Whether this user's camera is enabled"

    field :suppress, :boolean,
      allow_nil?: false,
      description: "Whether this user's permission to speak is denied"

    field :request_to_speak_timestamp, :utc_datetime,
      allow_nil?: true,
      description: "Time at which the user requested to speak (nullable ISO8601 timestamp)"
  end

  @doc """
  Create a VoiceState TypedStruct from a Nostrum VoiceState event struct.

  Accepts a `Nostrum.Struct.Event.VoiceState.t()` and creates an AshDiscord VoiceState TypedStruct.
  Also handles being passed a VoiceState payload (no-op for already-converted payloads) or a raw map for validation.
  """
  def new(%__MODULE__{} = voice_state_payload) do
    {:ok, voice_state_payload}
  end

  def new(%Nostrum.Struct.Event.VoiceState{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end

  def new(value) do
    super(value)
  end
end
