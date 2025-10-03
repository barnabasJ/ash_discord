defmodule AshDiscord.Consumer.Payloads.VoiceSpeakingUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord VOICE_SPEAKING_UPDATE event data.

  Wraps `Nostrum.Struct.Event.SpeakingUpdate.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.SpeakingUpdate struct"
  end
end
