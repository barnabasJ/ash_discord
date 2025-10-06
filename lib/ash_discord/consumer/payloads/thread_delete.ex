defmodule AshDiscord.Consumer.Payloads.ThreadDelete do
  @moduledoc """
  TypedStruct for Discord THREAD_DELETE event payload.

  Contains minimal thread identification data for deletion.

  The THREAD_DELETE event payload is a subset of the channel object,
  containing only the essential fields: id, guild_id, parent_id, and type.

  ## References
  - [Discord API - Thread Delete Event](https://discord.com/developers/docs/topics/gateway-events#thread-delete)
  - [Nostrum - Channel](https://hexdocs.pm/nostrum/Nostrum.Struct.Channel.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :id, :integer,
      allow_nil?: false,
      description: "The ID of the deleted thread"

    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :parent_id, :integer,
      allow_nil?: true,
      description: "The ID of the parent channel"

    field :type, :integer,
      allow_nil?: false,
      description: "The channel type (10, 11, or 12 for threads)"
  end

  @doc """
  Create a ThreadDelete TypedStruct from Nostrum thread delete event data.

  Accepts a `Nostrum.Struct.Channel.t()` with minimal fields for deletion.
  """
  def new(%Nostrum.Struct.Channel{} = nostrum_channel) do
    super(%{
      id: nostrum_channel.id,
      guild_id: nostrum_channel.guild_id,
      parent_id: nostrum_channel.parent_id,
      type: nostrum_channel.type
    })
  end
end
