defmodule AshDiscord.Consumer.Payloads.GuildMembersChunkEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_MEMBERS_CHUNK event data.

  Wraps map() to provide a unified AshDiscord type.

  ## References
  - [Discord API - Guild Members Chunk Event](https://discord.com/developers/docs/topics/gateway-events#guild-members-chunk)
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The GUILD_MEMBERS_CHUNK event data map"
  end
end
