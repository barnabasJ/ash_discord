defmodule AshDiscord.Changes.FromDiscord.ThreadListSync do
  @moduledoc """
  Transforms Discord ThreadListSync event data into Ash resource attributes.

  The THREAD_LIST_SYNC event is sent when the current user gains access to a channel
  and provides all active threads in that channel. This is primarily an informational
  event for tracking synchronization activities.

  Thread list sync events are not independently fetchable from the API,
  so only the `:data` argument is supported (no `:identity` fallback).

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.ThreadListSyncEvent.t()` with sync event data

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.ThreadListSyncEvent

        change AshDiscord.Changes.FromDiscord.ThreadListSync
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        %Payloads.ThreadListSyncEvent{} = sync_data ->
          transform_sync_event(changeset, sync_data)

        nil ->
          Ash.Changeset.add_error(
            changeset,
            "ThreadListSync requires data argument - thread list sync events are not independently fetchable from API"
          )

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.ThreadListSyncEvent{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_sync_event(changeset, sync_data) do
    changeset
    |> maybe_set_attribute(:guild_discord_id, sync_data.guild_id)
    |> maybe_set_attribute(:guild_id, sync_data.guild_id)
    |> maybe_set_attribute(:channel_ids, sync_data.channel_ids)
    |> maybe_set_attribute(:threads, sync_data.threads)
    |> maybe_set_attribute(:members, sync_data.members)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end
end
