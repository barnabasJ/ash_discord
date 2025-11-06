defmodule AshDiscord.Changes.FromDiscord.Channel do
  @moduledoc """
  Transforms Discord Channel data into Ash resource attributes.

  This change handles creating/updating Channel resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Channel.t()` with Discord channel data
  - `:identity` - Integer Discord channel ID for API fallback when data not provided

  ## Transformations

  Maps all Discord Channel attributes including:
  - Basic attributes: name, type, position, topic, nsfw
  - Voice channel attributes: bitrate, user_limit, rtc_region, video_quality_mode
  - Thread attributes: thread_metadata, message_count, member_count, newly_created
  - Forum attributes: available_tags, applied_tags, default_reaction_emoji, default_sort_order, default_forum_layout
  - DM attributes: recipients, icon
  - Timestamps: last_pin_timestamp
  - Relationships: guild, parent channel, owner, last_message

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Channel
        argument :identity, :integer

        change AshDiscord.Changes.FromDiscord.Channel
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.{ApiFetchers, Transformations}
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
      nil ->
        Ash.Changeset.before_transaction(changeset, fn changeset ->
          identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)

          # Extract discord_id from identity (can be integer or map with discord_id key)
          discord_id =
            if is_map(identity), do: Map.get(identity, :discord_id, identity), else: identity

          case ApiFetchers.fetch_channel(discord_id) do
            {:ok, %Payloads.Channel{} = channel_data} ->
              transform_channel(changeset, channel_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end
        end)

      %Payloads.Channel{} = channel_data ->
        # Data provided directly, use it
        transform_channel(changeset, channel_data)

      other ->
        Ash.Changeset.add_error(
          changeset,
          "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Channel{}, got: #{inspect(other)}"
        )
    end
  end

  defp transform_channel(changeset, channel_data) do
    changeset
    |> maybe_set_attribute(:discord_id, channel_data.id)
    |> maybe_set_attribute(:name, channel_data.name)
    |> maybe_set_attribute(:type, channel_data.type)
    |> maybe_set_attribute(:position, channel_data.position)
    |> maybe_set_attribute(:topic, channel_data.topic)
    |> maybe_set_attribute(:nsfw, channel_data.nsfw)
    |> maybe_set_attribute(:bitrate, channel_data.bitrate)
    |> maybe_set_attribute(:user_limit, channel_data.user_limit)
    |> maybe_set_attribute(:rate_limit_per_user, channel_data.rate_limit_per_user)
    |> maybe_set_attribute(:recipients, channel_data.recipients)
    |> maybe_set_attribute(:icon, channel_data.icon)
    |> maybe_set_attribute(:application_discord_id, channel_data.application_id)
    |> maybe_set_attribute(:rtc_region, channel_data.rtc_region)
    |> maybe_set_attribute(:video_quality_mode, channel_data.video_quality_mode)
    |> maybe_set_attribute(:message_count, channel_data.message_count)
    |> maybe_set_attribute(:member_count, channel_data.member_count)
    |> maybe_set_attribute(:thread_metadata, channel_data.thread_metadata)
    |> maybe_set_attribute(:member, channel_data.member)
    |> maybe_set_attribute(
      :default_auto_archive_duration,
      channel_data.default_auto_archive_duration
    )
    |> maybe_set_attribute(:permissions, channel_data.permissions)
    |> maybe_set_attribute(:newly_created, channel_data.newly_created)
    |> maybe_set_attribute(:available_tags, channel_data.available_tags)
    |> maybe_set_attribute(:applied_tags, channel_data.applied_tags)
    |> maybe_set_attribute(:default_reaction_emoji, channel_data.default_reaction_emoji)
    |> maybe_set_attribute(
      :default_thread_rate_limit_per_user,
      channel_data.default_thread_rate_limit_per_user
    )
    |> maybe_set_attribute(:default_sort_order, channel_data.default_sort_order)
    |> maybe_set_attribute(:default_forum_layout, channel_data.default_forum_layout)
    |> maybe_set_attribute(
      :permission_overwrites,
      Transformations.transform_permission_overwrites(channel_data.permission_overwrites)
    )
    |> maybe_set_datetime_attribute(:last_pin_timestamp, channel_data.last_pin_timestamp)
    |> maybe_manage_guild_relationship(channel_data.guild_id)
    |> maybe_manage_parent_relationship(channel_data.parent_id)
    |> maybe_manage_owner_relationship(channel_data.owner_id)
    |> maybe_manage_last_message_relationship(channel_data.last_message_id, channel_data.id)
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

  defp maybe_set_datetime_attribute(changeset, _field, nil), do: changeset

  defp maybe_set_datetime_attribute(changeset, field, value) do
    resource = changeset.resource

    if Ash.Resource.Info.attribute(resource, field) do
      Transformations.set_datetime_field(changeset, field, value)
    else
      changeset
    end
  end

  defp maybe_manage_guild_relationship(changeset, nil), do: changeset

  defp maybe_manage_guild_relationship(changeset, guild_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :guild) do
      Transformations.manage_guild_relationship(changeset, guild_id)
    else
      changeset
    end
  end

  defp maybe_manage_parent_relationship(changeset, nil), do: changeset

  defp maybe_manage_parent_relationship(changeset, parent_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :parent) do
      Ash.Changeset.manage_relationship(
        changeset,
        :parent,
        %{discord_id: parent_id, identity: parent_id},
        type: :append_and_remove,
        use_identities: [:discord_id],
        on_no_match: {:create, :from_discord}
      )
    else
      changeset
    end
  end

  defp maybe_manage_owner_relationship(changeset, nil), do: changeset

  defp maybe_manage_owner_relationship(changeset, owner_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :owner) do
      Transformations.manage_user_relationship(changeset, owner_id, :owner)
    else
      changeset
    end
  end

  defp maybe_manage_last_message_relationship(changeset, nil, _channel_id), do: changeset

  defp maybe_manage_last_message_relationship(changeset, message_id, channel_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :last_message) do
      Ash.Changeset.manage_relationship(
        changeset,
        :last_message,
        %{
          discord_id: message_id,
          channel_discord_id: channel_id,
          identity: %{discord_id: message_id, channel_discord_id: channel_id}
        },
        type: :append_and_remove,
        use_identities: [:discord_id],
        on_no_match: {:create, :from_discord}
      )
    else
      changeset
    end
  end
end
