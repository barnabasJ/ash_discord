defmodule AshDiscord.Consumer.Payloads.ChannelPinsUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord CHANNEL_PINS_UPDATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.ChannelPinsUpdate.t()`.
  """

  use Ash.TypedStruct

  typed_struct do
    field :guild_id, :integer,
      description: "The ID of the guild, if the pin update was on a guild"

    field :channel_id, :integer, allow_nil?: false, description: "The ID of the channel"

    field :last_pin_timestamp, :utc_datetime,
      description: "The time at which the most recent pinned message was pinned"
  end

  @doc """
  Create a ChannelPinsUpdateEvent TypedStruct from a Nostrum ChannelPinsUpdate event struct.

  Accepts a `Nostrum.Struct.Event.ChannelPinsUpdate.t()` and creates an AshDiscord ChannelPinsUpdateEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Event.ChannelPinsUpdate{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end
end
