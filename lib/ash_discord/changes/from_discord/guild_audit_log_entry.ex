defmodule AshDiscord.Changes.FromDiscord.GuildAuditLogEntry do
  @moduledoc """
  Transforms Discord Guild Audit Log Entry event data into Ash resource attributes.

  This change handles creating audit log entry records from Discord audit log events.
  Audit log entries are informational only and track actions taken in a guild.

  ## Arguments

  - `:data` - GuildAuditLogEntryCreateEvent TypedStruct with audit log entry data

  ## Example

      create :from_discord do
        argument :data, :map

        change AshDiscord.Changes.FromDiscord.GuildAuditLogEntry
      end
  """

  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
      nil ->
        Ash.Changeset.add_error(changeset, "data argument is required")

      %{
        id: id,
        action_type: action_type,
        changes: changes,
        options: options,
        reason: reason,
        target_id: target_id,
        user_id: user_id
      } ->
        transform_audit_log_entry(
          changeset,
          id,
          action_type,
          changes,
          options,
          reason,
          target_id,
          user_id
        )

      other ->
        Ash.Changeset.add_error(
          changeset,
          "Invalid data argument: expected GuildAuditLogEntryCreateEvent, got: #{inspect(other)}"
        )
    end
  end

  defp transform_audit_log_entry(
         changeset,
         id,
         action_type,
         changes,
         options,
         reason,
         target_id,
         user_id
       ) do
    changeset
    |> maybe_set_attribute(:discord_id, id)
    |> maybe_set_attribute(:action_type, action_type)
    |> maybe_set_attribute(:changes, changes)
    |> maybe_set_attribute(:options, options)
    |> maybe_set_attribute(:reason, reason)
    |> maybe_set_attribute(:target_discord_id, target_id)
    |> maybe_set_attribute(:user_discord_id, user_id)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    resource = changeset.resource

    if Ash.Resource.Info.attribute(resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end
end
