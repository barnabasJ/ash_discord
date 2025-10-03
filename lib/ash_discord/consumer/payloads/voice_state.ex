defmodule AshDiscord.Consumer.Payloads.VoiceState do
  @moduledoc """
  TypedStruct wrapper for Discord Voice State data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.VoiceState.t()`.
  This is an alias to VoiceStateEvent for consistency with other payload types.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer, description: "Guild ID this voice state is for (if applicable)"

    field :channel_id, :integer,
      description: "Channel ID this voice state is for (nil if user left voice)"

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

    field :self_stream, :boolean, description: "Whether this user is streaming using Go Live"

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
  Create a VoiceState TypedStruct from a Nostrum VoiceState event struct.

  Accepts a `Nostrum.Struct.Event.VoiceState.t()` and creates an AshDiscord VoiceState TypedStruct.
  """
  def new(%Nostrum.Struct.Event.VoiceState{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
