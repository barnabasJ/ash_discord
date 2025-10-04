defmodule AshDiscord.Changes.FromDiscord.ThreadMember do
  @moduledoc """
  Transforms Discord ThreadMember data into Ash resource attributes.

  Thread members are part of thread data and not independently fetchable,
  so only the `:data` argument is supported (no `:identity` fallback).

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.ThreadMember.t()` with thread member data

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.ThreadMember

        change AshDiscord.Changes.FromDiscord.ThreadMember
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.Transformations
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        %Payloads.ThreadMember{} = thread_member_data ->
          transform_thread_member(changeset, thread_member_data)

        nil ->
          Ash.Changeset.add_error(
            changeset,
            "ThreadMember requires data argument - thread members are not independently fetchable from API"
          )

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.ThreadMember{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_thread_member(changeset, thread_member_data) do
    changeset
    |> maybe_set_attribute(:thread_discord_id, thread_member_data.id)
    |> maybe_set_attribute(:thread_id, thread_member_data.id)
    |> maybe_set_attribute(:user_discord_id, thread_member_data.user_id)
    |> maybe_set_attribute(:user_id, thread_member_data.user_id)
    |> maybe_set_attribute(:guild_discord_id, thread_member_data.guild_id)
    |> maybe_set_attribute(:guild_id, thread_member_data.guild_id)
    |> maybe_set_attribute(:flags, thread_member_data.flags)
    |> maybe_set_datetime_field(:join_timestamp, thread_member_data.join_timestamp)
  end

  defp maybe_set_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_attribute(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Ash.Changeset.force_change_attribute(changeset, field, value)
    else
      changeset
    end
  end

  defp maybe_set_datetime_field(changeset, _field, nil), do: changeset

  defp maybe_set_datetime_field(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Transformations.set_datetime_field(changeset, field, value)
    else
      changeset
    end
  end
end
