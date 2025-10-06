defmodule AshDiscord.Changes.FromDiscord.ThreadMembersUpdate do
  @moduledoc """
  Transforms Discord ThreadMembersUpdate event data into Ash resource attributes.

  The THREAD_MEMBERS_UPDATE event is sent when anyone is added to or removed from a thread.
  This is primarily an informational event for tracking member changes.

  Thread members update events are not independently fetchable from the API,
  so only the `:data` argument is supported (no `:identity` fallback).

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.ThreadMembersUpdateEvent.t()` with members update data

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.ThreadMembersUpdateEvent

        change AshDiscord.Changes.FromDiscord.ThreadMembersUpdate
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        %Payloads.ThreadMembersUpdateEvent{} = update_data ->
          transform_members_update(changeset, update_data)

        nil ->
          Ash.Changeset.add_error(
            changeset,
            "ThreadMembersUpdate requires data argument - thread members update events are not independently fetchable from API"
          )

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.ThreadMembersUpdateEvent{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_members_update(changeset, update_data) do
    changeset
    |> maybe_set_attribute(:thread_discord_id, update_data.id)
    |> maybe_set_attribute(:thread_id, update_data.id)
    |> maybe_set_attribute(:guild_discord_id, update_data.guild_id)
    |> maybe_set_attribute(:guild_id, update_data.guild_id)
    |> maybe_set_attribute(:member_count, update_data.member_count)
    |> maybe_set_attribute(:added_members, update_data.added_members)
    |> maybe_set_attribute(:removed_member_ids, update_data.removed_member_ids)
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
