defmodule AshDiscord.Consumer.Payloads.GuildDelete do
  @moduledoc """
  TypedStruct for Discord GUILD_DELETE event payload.

  Contains guild data and unavailable status.
  """

  use Ash.TypedStruct

  alias AshDiscord.Consumer.Payloads.Guild

  typed_struct do
    field :old_guild, Guild,
      allow_nil?: false,
      description: "The guild that was deleted or became unavailable"

    field :unavailable, :boolean,
      allow_nil?: false,
      description:
        "Whether the guild is temporarily unavailable (true) or permanently deleted (false/nil)"
  end
end
