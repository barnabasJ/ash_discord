defmodule AshDiscord.Consumer.Payloads.ChannelUpdate do
  @moduledoc """
  TypedStruct for Discord CHANNEL_UPDATE event payload.

  Contains old and new channel data.
  """

  use Ash.TypedStruct

  typed_struct do
    field :old_channel, AshDiscord.Consumer.Payloads.Channel,
      allow_nil?: true,
      description: "The previous channel state (may be nil if not cached)"

    field :new_channel, AshDiscord.Consumer.Payloads.Channel,
      allow_nil?: false,
      description: "The updated channel state"
  end

  @doc """
  Create a ChannelUpdate TypedStruct from Nostrum channel update event data.

  Accepts a tuple `{old_channel, new_channel}` where each is a `Nostrum.Struct.Channel.t()`.
  """
  def new({old_channel, %Nostrum.Struct.Channel{} = new_channel}) do
    super(%{
      old_channel: old_channel && AshDiscord.Consumer.Payloads.Channel.new(old_channel),
      new_channel: AshDiscord.Consumer.Payloads.Channel.new(new_channel)
    })
  end
end
