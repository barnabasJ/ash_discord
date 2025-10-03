defmodule AshDiscord.Consumer.Payloads.GuildUpdate do
  @moduledoc """
  TypedStruct for Discord GUILD_UPDATE event payload.

  Contains old and new guild data.
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.Guild

  typed_struct do
    field :old_guild, Guild,
      allow_nil?: false,
      description: "The previous guild state"

    field :new_guild, Guild,
      allow_nil?: false,
      description: "The updated guild state"
  end
end
