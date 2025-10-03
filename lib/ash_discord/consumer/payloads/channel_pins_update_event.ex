defmodule AshDiscord.Consumer.Payloads.ChannelPinsUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord CHANNEL_PINS_UPDATE event data.

  Wraps `Nostrum.Struct.Event.ChannelPinsUpdate.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.ChannelPinsUpdate struct"
  end
end
