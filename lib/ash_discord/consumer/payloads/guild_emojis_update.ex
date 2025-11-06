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

  @doc """
  Create a GuildEmojisUpdate TypedStruct from Nostrum guild emojis update event data.

  Accepts a tuple `{guild_id, old_emojis, new_emojis}` where emojis are lists of `Nostrum.Struct.Emoji.t()`.
  """
  def new({guild_id, old_emojis, new_emojis})
      when is_integer(guild_id) and is_list(old_emojis) and is_list(new_emojis) do
    old_emojis_typed =
      Enum.map(old_emojis, fn emoji ->
        {:ok, typed_emoji} = Emoji.new(emoji)
        typed_emoji
      end)

    new_emojis_typed =
      Enum.map(new_emojis, fn emoji ->
        {:ok, typed_emoji} = Emoji.new(emoji)
        typed_emoji
      end)

    super(%{
      guild_id: guild_id,
      old_emojis: old_emojis_typed,
      new_emojis: new_emojis_typed
    })
  end
end
