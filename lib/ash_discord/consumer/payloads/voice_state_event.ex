defmodule AshDiscord.Consumer.Payloads.VoiceStateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord VOICE_STATE_UPDATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.VoiceState.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer, description: "Guild ID this voice state is for (if applicable)"

    field :channel_id, :integer,
      allow_nil?: false,
      description: "Channel ID this voice state is for"

    field :user_id, :integer, allow_nil?: false, description: "User ID this voice state is for"

    field :member, AshDiscord.Consumer.Payloads.Member,
      description: "Guild member this voice state is for"

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
      description: "Time at which the user requested to speak"
  end

  @doc """
  Create a VoiceStateEvent TypedStruct from a Nostrum VoiceState event struct.

  Accepts a `Nostrum.Struct.Event.VoiceState.t()` and creates an AshDiscord VoiceStateEvent TypedStruct.
  Also handles being passed a VoiceStateEvent payload (no-op for already-converted payloads).
  """
  def new(%__MODULE__{} = voice_state_payload) do
    {:ok, voice_state_payload}
  end

  def new(%Nostrum.Struct.Event.VoiceState{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
