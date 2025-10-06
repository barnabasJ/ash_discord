defmodule AshDiscord.Changes.FromDiscord.GuildScheduledEvent do
  @moduledoc """
  Transforms Discord Guild Scheduled Event data into Ash resource attributes.

  This change handles creating/updating GuildScheduledEvent resources from Discord data.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.GuildScheduledEvent.t()` with Discord event data

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.GuildScheduledEvent
        change AshDiscord.Changes.FromDiscord.GuildScheduledEvent
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.Transformations
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
      %Payloads.GuildScheduledEvent{} = event_data ->
        transform_scheduled_event(changeset, event_data)

      nil ->
        Ash.Changeset.add_error(
          changeset,
          "GuildScheduledEvent requires data argument with GuildScheduledEvent payload"
        )

      other ->
        Ash.Changeset.add_error(
          changeset,
          "Invalid data argument: expected %AshDiscord.Consumer.Payloads.GuildScheduledEvent{}, got: #{inspect(other)}"
        )
    end
  end

  defp transform_scheduled_event(changeset, event_data) do
    changeset
    |> Ash.Changeset.force_change_attribute(:discord_id, event_data.id)
    |> maybe_set_attribute(:guild_id, event_data.guild_id)
    |> maybe_set_attribute(:channel_id, event_data.channel_id)
    |> maybe_set_attribute(:creator_id, event_data.creator_id)
    |> maybe_set_attribute(:name, event_data.name)
    |> maybe_set_attribute(:description, event_data.description)
    |> Transformations.set_datetime_field(:scheduled_start_time, event_data.scheduled_start_time)
    |> Transformations.set_datetime_field(:scheduled_end_time, event_data.scheduled_end_time)
    |> maybe_set_attribute(:privacy_level, event_data.privacy_level)
    |> maybe_set_attribute(:status, event_data.status)
    |> maybe_set_attribute(:entity_type, event_data.entity_type)
    |> maybe_set_attribute(:entity_id, event_data.entity_id)
    |> maybe_set_attribute(:user_count, event_data.user_count)
    |> maybe_set_entity_metadata(event_data.entity_metadata)
    |> maybe_manage_guild_relationship(event_data.guild_id)
    |> maybe_manage_channel_relationship(event_data.channel_id)
    |> maybe_manage_creator_relationship(event_data.creator_id)
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

  defp maybe_set_entity_metadata(changeset, nil), do: changeset

  defp maybe_set_entity_metadata(changeset, %Payloads.GuildScheduledEventEntityMetadata{
         location: location
       }) do
    # Store entity metadata location if the resource has the field
    maybe_set_attribute(changeset, :entity_metadata_location, location)
  end

  # Manage guild relationship if exists on resource
  defp maybe_manage_guild_relationship(changeset, nil), do: changeset

  defp maybe_manage_guild_relationship(changeset, guild_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :guild) do
      Transformations.manage_guild_relationship(changeset, guild_id)
    else
      changeset
    end
  end

  # Manage channel relationship if exists on resource
  defp maybe_manage_channel_relationship(changeset, nil), do: changeset

  defp maybe_manage_channel_relationship(changeset, channel_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :channel) do
      Transformations.manage_channel_relationship(changeset, channel_id)
    else
      changeset
    end
  end

  # Manage creator (user) relationship if exists on resource
  defp maybe_manage_creator_relationship(changeset, nil), do: changeset

  defp maybe_manage_creator_relationship(changeset, creator_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :creator) do
      Transformations.manage_user_relationship(changeset, creator_id, :creator)
    else
      changeset
    end
  end
end
