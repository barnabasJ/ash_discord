defmodule AshDiscord.Consumer.Payloads.VoiceIncomingPacket do
  @moduledoc """
  TypedStruct wrapper for Discord voice incoming packet data.

  Wraps binary packet data to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :packet, :binary,
      allow_nil?: false,
      description: "The binary voice packet data"
  end
end
