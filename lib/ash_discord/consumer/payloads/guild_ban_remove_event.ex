defmodule AshDiscord.Consumer.Payloads.GuildBanRemoveEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_BAN_REMOVE event data.

  Wraps `Nostrum.Struct.Event.GuildBanRemove.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.GuildBanRemove struct"
  end
end
