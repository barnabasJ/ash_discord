defmodule AshDiscord.Consumer.Payloads.GuildStickersUpdate do
  @moduledoc """
  TypedStruct for Discord GUILD_STICKERS_UPDATE event payload.

  Contains guild ID and old/new sticker lists.

  ## References
  - [Discord API - Guild Stickers Update Event](https://discord.com/developers/docs/topics/gateway-events#guild-stickers-update)
  - [Nostrum - Sticker](https://hexdocs.pm/nostrum/Nostrum.Struct.Sticker.html)
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.Sticker

  typed_struct do
    field :guild_id, :integer,
      allow_nil?: false,
      description: "The ID of the guild"

    field :old_stickers, {:array, Sticker},
      allow_nil?: false,
      description: "The previous list of stickers"

    field :new_stickers, {:array, Sticker},
      allow_nil?: false,
      description: "The updated list of stickers"
  end
end
