defmodule AshDiscord.Consumer.Payloads.GuildUpdate do
  @moduledoc """
  TypedStruct for Discord GUILD_UPDATE event payload.

  Contains old and new guild data.
  """

  use Ash.TypedStruct

  typed_struct do
    field :old_guild, AshDiscord.Consumer.Payloads.Guild,
      allow_nil?: false,
      description: "The previous guild state"

    field :new_guild, AshDiscord.Consumer.Payloads.Guild,
      allow_nil?: false,
      description: "The updated guild state"
  end

  @doc """
  Create a GuildUpdate TypedStruct from Nostrum guild update event data.

  Accepts a tuple `{old_guild, new_guild}` where each is a `Nostrum.Struct.Guild.t()`.
  """
  def new({%Nostrum.Struct.Guild{} = old_guild, %Nostrum.Struct.Guild{} = new_guild}) do
    super(%{
      old_guild: AshDiscord.Consumer.Payloads.Guild.new(old_guild),
      new_guild: AshDiscord.Consumer.Payloads.Guild.new(new_guild)
    })
  end
end
