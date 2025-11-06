defmodule AshDiscord.Consumer.Payloads.GuildUpdate do
  @moduledoc """
  TypedStruct for Discord GUILD_UPDATE event payload.

  Contains old and new guild data.

  ## References
  - [Discord API - Guild Update Event](https://discord.com/developers/docs/topics/gateway-events#guild-update)
  - [Nostrum - Guild](https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :old_guild, AshDiscord.Consumer.Payloads.Guild,
      allow_nil?: true,
      description: "The previous guild state (may be nil if not cached)"

    field :new_guild, AshDiscord.Consumer.Payloads.Guild,
      allow_nil?: false,
      description: "The updated guild state"
  end

  @doc """
  Create a GuildUpdate TypedStruct from Nostrum guild update event data.

  Accepts a tuple `{old_guild, new_guild}` where each is a `Nostrum.Struct.Guild.t()`.
  """
  def new({old_guild, %Nostrum.Struct.Guild{} = new_guild}) do
    {:ok, new_guild_payload} = AshDiscord.Consumer.Payloads.Guild.new(new_guild)

    old_guild_payload =
      if old_guild do
        {:ok, payload} = AshDiscord.Consumer.Payloads.Guild.new(old_guild)
        payload
      else
        nil
      end

    super(%{
      old_guild: old_guild_payload,
      new_guild: new_guild_payload
    })
  end
end
