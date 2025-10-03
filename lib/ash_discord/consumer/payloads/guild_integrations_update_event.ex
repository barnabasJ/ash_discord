defmodule AshDiscord.Consumer.Payloads.GuildIntegrationsUpdateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_INTEGRATIONS_UPDATE event data.

  Wraps `Nostrum.Struct.Event.GuildIntegrationsUpdate.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.GuildIntegrationsUpdate struct"
  end
end
