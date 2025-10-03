defmodule AshDiscord.Consumer.Payloads.GuildDelete do
  @moduledoc """
  TypedStruct for Discord GUILD_DELETE event payload.

  Contains guild data and unavailable status.
  """

  use Ash.TypedStruct

  typed_struct do
    field :old_guild, AshDiscord.Consumer.Payloads.Guild,
      allow_nil?: false,
      description: "The guild that was deleted or became unavailable"

    field :unavailable, :boolean,
      allow_nil?: false,
      description:
        "Whether the guild is temporarily unavailable (true) or permanently deleted (false/nil)"
  end

  @doc """
  Create a GuildDelete TypedStruct from Nostrum guild delete event data.

  Accepts a tuple `{old_guild, unavailable}` where old_guild is a `Nostrum.Struct.Guild.t()` and unavailable is a boolean.
  """
  def new({%Nostrum.Struct.Guild{} = old_guild, unavailable}) when is_boolean(unavailable) do
    super(%{
      old_guild: AshDiscord.Consumer.Payloads.Guild.new(old_guild),
      unavailable: unavailable
    })
  end
end
