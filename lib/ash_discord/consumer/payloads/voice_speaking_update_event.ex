defmodule AshDiscord.Consumer.Payloads.VoiceSpeakingUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord VOICE_SPEAKING_UPDATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.SpeakingUpdate.t()`.
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
  """
  def new(%Nostrum.Struct.Event.SpeakingUpdate{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
