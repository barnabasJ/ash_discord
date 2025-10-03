defmodule AshDiscord.Consumer.Payloads.VoiceStateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord VOICE_STATE_UPDATE event data.

  Wraps `Nostrum.Struct.Event.VoiceState.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.VoiceState struct"
  end
end
