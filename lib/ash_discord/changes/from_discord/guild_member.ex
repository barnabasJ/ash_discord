defmodule AshDiscord.Changes.FromDiscord.GuildMember do
  @moduledoc """
  Transforms Discord Guild Member data into Ash resource attributes.

  This change handles creating/updating GuildMember resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Member.t()` with Discord member data
  - `:identity` - Map with `%{guild_id: integer, user_id: integer}` for API fallback

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Member
        argument :identity, :map

        change AshDiscord.Changes.FromDiscord.GuildMember
      end
  """

  use Ash.Resource.Change

  alias AshDiscord.Changes.FromDiscord.{ApiFetchers, Transformations}
  alias AshDiscord.Consumer.Payloads

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_transaction(changeset, fn changeset ->
      # API calls happen here, OUTSIDE transaction
      case Ash.Changeset.get_argument(changeset, :data) do
        nil ->
          # No data provided, fetch from API using identity
          identity = Ash.Changeset.get_argument(changeset, :identity)

          case ApiFetchers.fetch_member(identity) do
            {:ok, %Payloads.Member{} = member_data} ->
              transform_guild_member(changeset, member_data, identity)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.Member{} = member_data ->
          # Data provided directly, use it
          # Extract identity from arguments if available
          identity = Ash.Changeset.get_argument(changeset, :identity)
          transform_guild_member(changeset, member_data, identity)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Member{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp transform_guild_member(changeset, member_data, identity) do
    # Get guild_discord_id from identity map
    guild_discord_id = identity[:guild_id] || identity["guild_id"]
    user_discord_id = member_data.user_id

    changeset
    |> maybe_set_attribute(:nick, member_data.nick)
    |> maybe_set_attribute(:avatar, member_data.avatar)
    |> maybe_set_attribute(:flags, member_data.flags)
    |> Transformations.set_datetime_field(:joined_at, member_data.joined_at)
    |> Transformations.set_datetime_field(:premium_since, member_data.premium_since)
    |> Transformations.set_datetime_field(
      :communication_disabled_until,
      member_data.communication_disabled_until
    )
    |> maybe_set_member_boolean_attributes(member_data)
    |> maybe_manage_guild_relationship(guild_discord_id)
    |> maybe_manage_user_relationship(user_discord_id)
  end

  defp maybe_set_member_boolean_attributes(changeset, member_data) do
    changeset
    |> maybe_set_attribute(:deaf, member_data.deaf)
    |> maybe_set_attribute(:mute, member_data.mute)
    |> maybe_set_attribute(:pending, member_data.pending)
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

  # Manage guild relationship if exists on resource
  defp maybe_manage_guild_relationship(changeset, nil), do: changeset

  defp maybe_manage_guild_relationship(changeset, guild_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :guild) do
      Transformations.manage_guild_relationship(changeset, guild_discord_id)
    else
      changeset
    end
  end

  # Manage user relationship if exists on resource
  defp maybe_manage_user_relationship(changeset, nil), do: changeset

  defp maybe_manage_user_relationship(changeset, user_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :user) do
      Transformations.manage_user_relationship(changeset, user_discord_id)
    else
      changeset
    end
  end
end
