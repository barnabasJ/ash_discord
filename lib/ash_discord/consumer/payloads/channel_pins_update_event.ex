defmodule AshDiscord.Consumer.Payloads.ChannelPinsUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord CHANNEL_PINS_UPDATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Event.ChannelPinsUpdate.t()`.

  ## References
  - [Discord API - Channel Pins Update Event](https://discord.com/developers/docs/topics/gateway-events#channel-pins-update)
  - [Nostrum - Event.ChannelPinsUpdate](https://hexdocs.pm/nostrum/Nostrum.Struct.Event.ChannelPinsUpdate.html)
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
  If already a ChannelPinsUpdateEvent struct, returns it as-is.
  """
  def new(%__MODULE__{} = event) do
    {:ok, event}
  end

  def new(%Nostrum.Struct.Event.ChannelPinsUpdate{} = nostrum_event) do
    super(Map.from_struct(nostrum_event))
  end

  # Handle plain maps (for testing/edge cases)
  def new(attrs) when is_map(attrs) do
    super(attrs)
  end
end
