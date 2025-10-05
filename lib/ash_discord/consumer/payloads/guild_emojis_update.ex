defmodule AshDiscord.Consumer.Payloads.GuildEmojisUpdate do
  @moduledoc """
  TypedStruct for Discord GUILD_EMOJIS_UPDATE event payload.

  Contains guild ID and old/new emoji lists.

  ## References
  - [Discord API - Guild Emojis Update Event](https://discord.com/developers/docs/topics/gateway-events#guild-emojis-update)
  - [Nostrum - Emoji](https://hexdocs.pm/nostrum/Nostrum.Struct.Emoji.html)
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.Emoji

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :old_emojis, {:array, Emoji},
      allow_nil?: false,
      description: "The previous list of emojis"

    field :new_emojis, {:array, Emoji},
      allow_nil?: false,
      description: "The updated list of emojis"
  end
end
