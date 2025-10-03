defmodule AshDiscord.Consumer.Payloads.VoiceServerUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord VOICE_SERVER_UPDATE event data.

  Wraps `Nostrum.Struct.Event.VoiceServerUpdate.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.VoiceServerUpdate struct"
  end
end
