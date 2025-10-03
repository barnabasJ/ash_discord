defmodule AshDiscord.Consumer.Payloads.GuildIntegrationDeleteEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_INTEGRATION_DELETE event data.

  Wraps `Nostrum.Struct.Event.GuildIntegrationDelete.t()` to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The Nostrum.Struct.Event.GuildIntegrationDelete struct"
  end
end
