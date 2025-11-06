defmodule AshDiscord.Changes.FromDiscord.Thread do
  @moduledoc """
  Transforms Discord Thread data into Ash resource attributes.

  Threads are represented as Channel objects in Discord (types 10, 11, 12).
  This change handles creating/updating Thread resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Thread.t()` with Discord thread data
  - `:identity` - Integer Discord thread ID for API fallback when data not provided

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Thread
        argument :identity, :integer

        change AshDiscord.Changes.FromDiscord.Thread
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.{ApiFetchers, Transformations}
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)

          case ApiFetchers.fetch_channel(identity) do
            {:ok, %Payloads.Channel{} = channel_data} ->
              # Channels are threads - convert the struct by creating Thread from Channel map
              thread_map = Map.from_struct(channel_data)

              {:ok, thread_data} =
                Payloads.Thread.new(struct!(Nostrum.Struct.Channel, thread_map))

              transform_thread(changeset, thread_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.Thread{} = thread_data ->
          # Data provided directly, use it
          transform_thread(changeset, thread_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Thread{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_thread(changeset, thread_data) do
    changeset
    |> maybe_set_attribute(:discord_id, thread_data.id)
    |> maybe_set_attribute(:name, thread_data.name)
    |> maybe_set_attribute(:type, thread_data.type)
    |> maybe_set_attribute(:position, thread_data.position)
    |> maybe_set_attribute(:topic, thread_data.topic)
    |> maybe_set_attribute(:nsfw, thread_data.nsfw)
    |> maybe_set_attribute(:parent_discord_id, thread_data.parent_id)
    |> maybe_set_attribute(:guild_discord_id, thread_data.guild_id)
    |> maybe_set_attribute(:owner_discord_id, thread_data.owner_id)
    |> maybe_set_attribute(:message_count, thread_data.message_count)
    |> maybe_set_attribute(:member_count, thread_data.member_count)
    |> maybe_set_attribute(:thread_metadata, thread_data.thread_metadata)
    |> maybe_set_attribute(:rate_limit_per_user, thread_data.rate_limit_per_user)
    |> maybe_set_attribute(:last_message_id, thread_data.last_message_id)
    |> maybe_set_datetime_field(:last_pin_timestamp, thread_data.last_pin_timestamp)
    |> maybe_set_attribute(
      :default_auto_archive_duration,
      thread_data.default_auto_archive_duration
    )
    |> maybe_set_attribute(:newly_created, thread_data.newly_created)
    |> maybe_set_attribute(:applied_tags, thread_data.applied_tags)
    |> maybe_set_attribute(
      :permission_overwrites,
      Transformations.transform_permission_overwrites(thread_data.permission_overwrites)
    )
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

  defp maybe_set_datetime_field(changeset, _field, nil), do: changeset

  defp maybe_set_datetime_field(changeset, field, value) do
    if Ash.Resource.Info.attribute(changeset.resource, field) do
      Transformations.set_datetime_field(changeset, field, value)
    else
      changeset
    end
  end
end
