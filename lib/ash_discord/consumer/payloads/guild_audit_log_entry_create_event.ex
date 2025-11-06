defmodule AshDiscord.Consumer.Payloads.GuildAuditLogEntryCreateEvent do
  @moduledoc """
  TypedStruct wrapper for Discord GUILD_AUDIT_LOG_ENTRY_CREATE event data.

  Provides a unified AshDiscord type with all fields from `Nostrum.Struct.Guild.AuditLogEntry.t()`.

  ## References
  - [Discord API - Guild Audit Log Entry Create Event](https://discord.com/developers/docs/topics/gateway-events#guild-audit-log-entry-create)
  - [Nostrum - Guild.AuditLogEntry](https://hexdocs.pm/nostrum/Nostrum.Struct.Guild.AuditLogEntry.html)
  """

  use Ash.TypedStruct

  typed_struct do
    field :action_type, :integer,
      allow_nil?: false,
      description: "Type of action that occurred (audit log event identifier)"

    field :changes, {:array, :map},
      allow_nil?: true,
      description: "Changes made to the target_id (optional)"

    field :id, :integer,
      allow_nil?: false,
      description: "ID of the audit log entry"

    field :options, :map,
      allow_nil?: true,
      description: "Optional audit entry info (optional)"

    field :reason, :string,
      allow_nil?: true,
      description: "Reason for the change (optional)"

    field :target_id, :string,
      allow_nil?: true,
      description: "ID of the affected entity (optional)"

    field :user_id, :integer,
      allow_nil?: true,
      description: "ID of the user who made the changes (optional)"
  end

  @doc """
  Create a GuildAuditLogEntryCreateEvent TypedStruct from a Nostrum AuditLogEntry struct.

  Accepts a `Nostrum.Struct.Guild.AuditLogEntry.t()` and creates an AshDiscord GuildAuditLogEntryCreateEvent TypedStruct.
  """
  def new(%Nostrum.Struct.Guild.AuditLogEntry{} = nostrum_entry) do
    super(Map.from_struct(nostrum_entry))
  end
end
