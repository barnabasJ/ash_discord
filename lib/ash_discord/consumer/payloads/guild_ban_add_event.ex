defmodule AshDiscord.Consumer.Payloads.GuildBanAddEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_BAN_ADD event data.

  Wraps `Nostrum.Struct.Event.GuildBanAdd.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.GuildBanAdd struct"
  end
end
