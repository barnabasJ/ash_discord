defmodule AshDiscord.Consumer.Payloads.ChannelUpdate do
  @moduledoc """
  TypedStruct for Discord CHANNEL_UPDATE event payload.

  Contains old and new channel data.
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.Channel

  typed_struct do
    field :old_channel, Channel,
      allow_nil?: true,
      description: "The previous channel state (may be nil if not cached)"

    field :new_channel, Channel,
      allow_nil?: false,
      description: "The updated channel state"
  end
end
