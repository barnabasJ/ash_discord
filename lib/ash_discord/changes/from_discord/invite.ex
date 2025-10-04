defmodule AshDiscord.Changes.FromDiscord.Invite do
  @moduledoc """
  Transforms Discord Invite data into Ash resource attributes.

  This change handles creating/updating Invite resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Invite.t()` with Discord invite data
  - `:identity` - String invite code for API fallback when data not provided

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Invite
        argument :identity, :string

        change AshDiscord.Changes.FromDiscord.Invite
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.Transformations
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument_or_attribute(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)

          case fetch_invite(identity) do
            {:ok, %Payloads.Invite{} = invite_data} ->
              transform_invite(changeset, invite_data)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.Invite{} = invite_data ->
          # Data provided directly, use it
          transform_invite(changeset, invite_data)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Invite{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp fetch_invite(code) when is_binary(code) do
    case Nostrum.Api.get_invite(code) do
      {:ok, invite} -> {:ok, Payloads.Invite.new(invite)}
      {:error, reason} -> {:error, reason}
    end
  rescue
    ArgumentError -> {:error, :api_unavailable}
  end

  defp fetch_invite(_), do: {:error, "Identity must be a string invite code"}

  defp transform_invite(changeset, invite_data) do
    # Handle both API format (nested objects) and event format (flat IDs)
    guild_id =
      case invite_data.guild do
        nil -> invite_data.guild_id
        guild_obj when is_map(guild_obj) -> get_nested_id(guild_obj)
      end

    channel_id =
      case invite_data.channel do
        nil -> invite_data.channel_id
        channel_obj when is_map(channel_obj) -> get_nested_id(channel_obj)
      end

    changeset
    |> maybe_set_attribute(:code, invite_data.code)
    |> maybe_set_attribute(:guild_discord_id, guild_id)
    |> maybe_set_attribute(:guild_id, guild_id)
    |> maybe_set_attribute(:channel_discord_id, channel_id)
    |> maybe_set_attribute(:channel_id, channel_id)
    |> maybe_manage_guild_relationship(guild_id)
    |> maybe_manage_channel_relationship(channel_id)
    |> maybe_set_attribute(:inviter_discord_id, get_nested_id(invite_data.inviter))
    |> maybe_set_attribute(:inviter_id, get_nested_id(invite_data.inviter))
    |> maybe_set_attribute(:target_user_discord_id, get_nested_id(invite_data.target_user))
    |> maybe_set_attribute(:target_user_id, get_nested_id(invite_data.target_user))
    |> maybe_set_attribute(:target_type, invite_data.target_type)
    |> maybe_set_attribute(:target_user_type, invite_data.target_user_type)
    |> maybe_set_attribute(:approximate_presence_count, invite_data.approximate_presence_count)
    |> maybe_set_attribute(:approximate_member_count, invite_data.approximate_member_count)
    |> maybe_set_attribute(:uses, invite_data.uses)
    |> maybe_set_attribute(:max_uses, invite_data.max_uses)
    |> maybe_set_attribute(:max_age, invite_data.max_age)
    |> maybe_set_attribute(:temporary, invite_data.temporary)
    |> maybe_set_datetime_field(:created_at, invite_data.created_at)
    |> maybe_set_datetime_field(:expires_at, invite_data.expires_at)
    |> maybe_set_attribute(:stage_instance, invite_data.stage_instance)
    |> maybe_set_attribute(:guild_scheduled_event, invite_data.guild_scheduled_event)
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

  defp maybe_manage_guild_relationship(changeset, nil), do: changeset

  defp maybe_manage_guild_relationship(changeset, guild_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :guild) do
      Transformations.manage_guild_relationship(changeset, guild_discord_id)
    else
      changeset
    end
  end

  defp maybe_manage_channel_relationship(changeset, nil), do: changeset

  defp maybe_manage_channel_relationship(changeset, channel_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :channel) do
      # Pass both discord_id (for lookup) and identity (for API fetch if not found)
      Ash.Changeset.manage_relationship(
        changeset,
        :channel,
        %{discord_id: channel_discord_id, identity: channel_discord_id},
        type: :append_and_remove,
        use_identities: [:discord_id],
        on_no_match: {:create, :from_discord}
      )
    else
      changeset
    end
  end

  defp get_nested_id(nil), do: nil
  defp get_nested_id(%{id: id}), do: id
  defp get_nested_id(map) when is_map(map), do: map[:id] || map["id"]
  defp get_nested_id(_), do: nil
end
