defmodule AshDiscord.Consumer.Payloads.VoiceReadyEvent do
  @moduledoc """
  TypedStruct wrapper for Discord VOICE_READY event data.

  Wraps `Nostrum.Struct.Event.VoiceReady.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.VoiceReady struct"
  end
end
