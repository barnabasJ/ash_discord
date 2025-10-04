defmodule AshDiscord.Changes.FromDiscord.Role do
  @moduledoc """
  Transforms Discord Role data into Ash resource attributes.

  This change handles creating/updating Role resources from Discord data,
  with support for both direct TypedStruct payloads and API fallback using
  identity-based fetching.

  ## Arguments

  - `:data` - TypedStruct `AshDiscord.Consumer.Payloads.Role.t()` with Discord role data
  - `:identity` - Map with `%{guild_id: integer, role_id: integer}` for API fallback

  ## Example

      create :from_discord do
        argument :data, AshDiscord.Consumer.Payloads.Role
        argument :identity, :map

        change AshDiscord.Changes.FromDiscord.Role
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

          case fetch_role_from_identity(identity) do
            {:ok, %Payloads.Role{} = role_data} ->
              transform_role(changeset, role_data, identity)

            {:error, reason} ->
              Ash.Changeset.add_error(changeset, reason)
          end

        %Payloads.Role{} = role_data ->
          # Data provided directly, use it
          identity = Ash.Changeset.get_argument_or_attribute(changeset, :identity)
          transform_role(changeset, role_data, identity)

        other ->
          Ash.Changeset.add_error(
            changeset,
            "Invalid data argument: expected %AshDiscord.Consumer.Payloads.Role{}, got: #{inspect(other)}"
          )
      end
    end)
  end

  defp fetch_role_from_identity(%{guild_id: guild_id, role_id: role_id}) do
    # Fetch role from guild
    case Nostrum.Api.Guild.roles(guild_id) do
      {:ok, roles} ->
        case Enum.find(roles, fn role -> role.id == role_id end) do
          nil -> {:error, "Role #{role_id} not found in guild #{guild_id}"}
          role -> {:ok, Payloads.Role.new(role)}
        end

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    ArgumentError -> {:error, :api_unavailable}
  end

  defp fetch_role_from_identity(_),
    do: {:error, "Identity must be a map with guild_id and role_id"}

  defp transform_role(changeset, role_data, identity) do
    guild_discord_id = identity[:guild_id] || identity["guild_id"]

    changeset
    |> maybe_set_attribute(:discord_id, role_data.id)
    |> maybe_set_attribute(:name, role_data.name)
    |> maybe_set_attribute(:color, role_data.color)
    |> maybe_set_attribute(:permissions, to_string(role_data.permissions))
    |> maybe_set_attribute(:hoist, role_data.hoist)
    |> maybe_set_attribute(:icon, role_data.icon)
    |> maybe_set_attribute(:unicode_emoji, role_data.unicode_emoji)
    |> maybe_set_attribute(:position, role_data.position)
    |> maybe_set_attribute(:managed, role_data.managed)
    |> maybe_set_attribute(:mentionable, role_data.mentionable)
    |> maybe_manage_guild_relationship(guild_discord_id)
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

  defp maybe_manage_guild_relationship(changeset, nil), do: changeset

  defp maybe_manage_guild_relationship(changeset, guild_discord_id) do
    if Ash.Resource.Info.relationship(changeset.resource, :guild) do
      Transformations.manage_guild_relationship(changeset, guild_discord_id)
    else
      changeset
    end
  end
end
