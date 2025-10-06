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

  @doc """
  Create a GuildStickersUpdate TypedStruct from Nostrum guild stickers update event data.

  Accepts a tuple `{guild_id, old_stickers, new_stickers}` where stickers are lists of `Nostrum.Struct.Sticker.t()`.
  """
  def new({guild_id, old_stickers, new_stickers})
      when is_integer(guild_id) and is_list(old_stickers) and is_list(new_stickers) do
    old_stickers_typed =
      Enum.map(old_stickers, fn sticker ->
        {:ok, typed_sticker} = Sticker.new(sticker)
        typed_sticker
      end)

    new_stickers_typed =
      Enum.map(new_stickers, fn sticker ->
        {:ok, typed_sticker} = Sticker.new(sticker)
        typed_sticker
      end)

    super(%{
      guild_id: guild_id,
      old_stickers: old_stickers_typed,
      new_stickers: new_stickers_typed
    })
  end
end
