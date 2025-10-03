defmodule AshDiscord.Consumer.Payloads.GuildAuditLogEntryCreateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_AUDIT_LOG_ENTRY_CREATE event data.

  Wraps map() to provide a unified AshDiscord type.
  """

  use Ash.TypedStruct

  typed_struct do
    field :data, :map,
      allow_nil?: false,
      description: "The GUILD_AUDIT_LOG_ENTRY_CREATE event data map"
  end
end
